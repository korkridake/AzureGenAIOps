"""
RAG Pipeline for document retrieval and augmented generation.
"""

from typing import List, Dict, Any, Optional
from azure.search.documents import SearchClient
from azure.core.credentials import AzureKeyCredential
from openai import AzureOpenAI
from ..common import LLMConfig, get_logger
from ..embeddings import EmbeddingGenerator

logger = get_logger(__name__)


class RAGPipeline:
    """
    Complete RAG (Retrieval-Augmented Generation) pipeline.
    """
    
    def __init__(self, config: LLMConfig = None):
        """Initialize RAG pipeline."""
        self.config = config or LLMConfig()
        
        # Initialize Azure AI Search client
        if self.config.azure_search_endpoint and self.config.azure_search_api_key:
            self.search_client = SearchClient(
                endpoint=self.config.azure_search_endpoint,
                index_name=self.config.azure_search_index_name,
                credential=AzureKeyCredential(self.config.azure_search_api_key)
            )
        else:
            logger.warning("Azure AI Search not configured")
            self.search_client = None
        
        # Initialize OpenAI client
        self.openai_client = AzureOpenAI(
            api_key=self.config.azure_openai_api_key,
            azure_endpoint=self.config.azure_openai_endpoint,
            api_version=self.config.azure_openai_api_version
        )
        
        # Initialize embedding generator
        self.embedding_generator = EmbeddingGenerator(config)
    
    def retrieve_documents(
        self, 
        query: str, 
        top_k: int = 5, 
        score_threshold: float = 0.7
    ) -> List[Dict[str, Any]]:
        """
        Retrieve relevant documents based on query.
        
        Args:
            query: Search query
            top_k: Number of documents to retrieve
            score_threshold: Minimum relevance score
            
        Returns:
            List of retrieved documents with metadata
        """
        if not self.search_client:
            logger.error("Azure AI Search not configured")
            return []
        
        try:
            # Generate query embedding
            query_embedding = self.embedding_generator.generate_embedding(query)
            
            # Perform vector search
            results = self.search_client.search(
                search_text=query,
                vector_queries=[{
                    "vector": query_embedding,
                    "k_nearest_neighbors": top_k,
                    "fields": "content_vector"
                }],
                top=top_k,
                include_total_count=True
            )
            
            documents = []
            for result in results:
                score = result.get("@search.score", 0)
                if score >= score_threshold:
                    documents.append({
                        "content": result.get("content", ""),
                        "title": result.get("title", ""),
                        "source": result.get("source", ""),
                        "score": score,
                        "metadata": result.get("metadata", {})
                    })
            
            logger.info(f"Retrieved {len(documents)} documents for query: {query[:50]}...")
            return documents
        
        except Exception as e:
            logger.error(f"Document retrieval failed: {e}")
            return []
    
    def generate_augmented_response(
        self, 
        query: str, 
        retrieved_docs: List[Dict[str, Any]], 
        system_prompt: str = None,
        max_tokens: int = 1000,
        temperature: float = 0.7
    ) -> Dict[str, Any]:
        """
        Generate response using retrieved documents as context.
        
        Args:
            query: User query
            retrieved_docs: Documents retrieved for context
            system_prompt: Optional system prompt
            max_tokens: Maximum tokens in response
            temperature: Response randomness
            
        Returns:
            Generated response with metadata
        """
        try:
            # Build context from retrieved documents
            context = self._build_context(retrieved_docs)
            
            # Prepare messages
            messages = []
            
            if system_prompt:
                messages.append({"role": "system", "content": system_prompt})
            else:
                messages.append({
                    "role": "system", 
                    "content": "You are a helpful assistant. Use the provided context to answer questions accurately. If the context doesn't contain relevant information, say so."
                })
            
            # Add context and user query
            user_message = f"Context:\n{context}\n\nQuestion: {query}"
            messages.append({"role": "user", "content": user_message})
            
            # Generate response
            response = self.openai_client.chat.completions.create(
                model=self.config.azure_openai_deployment_name,
                messages=messages,
                max_tokens=max_tokens,
                temperature=temperature
            )
            
            return {
                "response": response.choices[0].message.content,
                "usage": {
                    "prompt_tokens": response.usage.prompt_tokens,
                    "completion_tokens": response.usage.completion_tokens,
                    "total_tokens": response.usage.total_tokens
                },
                "retrieved_docs_count": len(retrieved_docs),
                "sources": [doc.get("source", "") for doc in retrieved_docs]
            }
        
        except Exception as e:
            logger.error(f"Response generation failed: {e}")
            return {
                "response": "I apologize, but I encountered an error while generating a response.",
                "error": str(e)
            }
    
    def query(
        self, 
        question: str, 
        top_k: int = 5, 
        score_threshold: float = 0.7,
        system_prompt: str = None,
        max_tokens: int = 1000,
        temperature: float = 0.7
    ) -> Dict[str, Any]:
        """
        Complete RAG query: retrieve documents and generate response.
        
        Args:
            question: User question
            top_k: Number of documents to retrieve
            score_threshold: Minimum relevance score
            system_prompt: Optional system prompt
            max_tokens: Maximum tokens in response
            temperature: Response randomness
            
        Returns:
            Complete RAG response
        """
        # Retrieve relevant documents
        retrieved_docs = self.retrieve_documents(
            query=question,
            top_k=top_k,
            score_threshold=score_threshold
        )
        
        # Generate augmented response
        response = self.generate_augmented_response(
            query=question,
            retrieved_docs=retrieved_docs,
            system_prompt=system_prompt,
            max_tokens=max_tokens,
            temperature=temperature
        )
        
        # Add retrieval metadata
        response["retrieval"] = {
            "documents_found": len(retrieved_docs),
            "search_query": question,
            "score_threshold": score_threshold
        }
        
        return response
    
    def _build_context(self, documents: List[Dict[str, Any]], max_length: int = 8000) -> str:
        """
        Build context string from retrieved documents.
        
        Args:
            documents: Retrieved documents
            max_length: Maximum context length
            
        Returns:
            Formatted context string
        """
        context_parts = []
        current_length = 0
        
        for doc in documents:
            title = doc.get("title", "")
            content = doc.get("content", "")
            source = doc.get("source", "")
            
            # Format document
            doc_text = f"Document: {title}\nSource: {source}\nContent: {content}\n\n"
            
            # Check if adding this document would exceed max length
            if current_length + len(doc_text) > max_length:
                # Truncate the last document if needed
                remaining_length = max_length - current_length
                if remaining_length > 100:  # Only add if there's meaningful space
                    doc_text = doc_text[:remaining_length] + "...\n\n"
                    context_parts.append(doc_text)
                break
            
            context_parts.append(doc_text)
            current_length += len(doc_text)
        
        return "".join(context_parts)
    
    def evaluate_retrieval_quality(self, queries_and_expected: List[Dict[str, Any]]) -> Dict[str, float]:
        """
        Evaluate retrieval quality using test queries.
        
        Args:
            queries_and_expected: List of {"query": str, "expected_sources": List[str]}
            
        Returns:
            Evaluation metrics
        """
        total_queries = len(queries_and_expected)
        precision_scores = []
        recall_scores = []
        
        for item in queries_and_expected:
            query = item["query"]
            expected_sources = set(item["expected_sources"])
            
            # Retrieve documents
            retrieved_docs = self.retrieve_documents(query, top_k=10)
            retrieved_sources = set(doc.get("source", "") for doc in retrieved_docs)
            
            # Calculate precision and recall
            if retrieved_sources:
                precision = len(expected_sources & retrieved_sources) / len(retrieved_sources)
                precision_scores.append(precision)
            
            if expected_sources:
                recall = len(expected_sources & retrieved_sources) / len(expected_sources)
                recall_scores.append(recall)
        
        avg_precision = sum(precision_scores) / len(precision_scores) if precision_scores else 0
        avg_recall = sum(recall_scores) / len(recall_scores) if recall_scores else 0
        f1_score = 2 * (avg_precision * avg_recall) / (avg_precision + avg_recall) if (avg_precision + avg_recall) > 0 else 0
        
        return {
            "precision": avg_precision,
            "recall": avg_recall,
            "f1_score": f1_score,
            "total_queries": total_queries
        }