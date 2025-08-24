"""
Embedding generation using Azure OpenAI embedding models.
"""

import numpy as np
from typing import List, Dict, Any, Union
from openai import AzureOpenAI
from ..common import LLMConfig, get_logger

logger = get_logger(__name__)


class EmbeddingGenerator:
    """
    Generate embeddings using Azure OpenAI embedding models.
    """
    
    def __init__(self, config: LLMConfig = None):
        """Initialize embedding generator."""
        self.config = config or LLMConfig()
        
        self.client = AzureOpenAI(
            api_key=self.config.azure_openai_api_key,
            azure_endpoint=self.config.azure_openai_endpoint,
            api_version=self.config.azure_openai_api_version
        )
        
        self.model_name = self.config.embedding_model_name
        self.dimensions = self.config.embedding_dimensions
    
    def generate_embedding(self, text: str) -> List[float]:
        """
        Generate embedding for a single text.
        
        Args:
            text: Input text
            
        Returns:
            Embedding vector
        """
        try:
            # Clean and validate input
            text = text.strip()
            if not text:
                logger.warning("Empty text provided for embedding")
                return [0.0] * self.dimensions
            
            response = self.client.embeddings.create(
                input=text,
                model=self.model_name
            )
            
            embedding = response.data[0].embedding
            
            # Validate embedding dimensions
            if len(embedding) != self.dimensions:
                logger.warning(f"Unexpected embedding dimensions: {len(embedding)} vs {self.dimensions}")
            
            return embedding
            
        except Exception as e:
            logger.error(f"Embedding generation failed for text: {text[:50]}..., error: {e}")
            return [0.0] * self.dimensions
    
    def generate_embeddings_batch(
        self, 
        texts: List[str], 
        batch_size: int = 100
    ) -> List[List[float]]:
        """
        Generate embeddings for multiple texts in batches.
        
        Args:
            texts: List of input texts
            batch_size: Batch size for processing
            
        Returns:
            List of embedding vectors
        """
        embeddings = []
        
        for i in range(0, len(texts), batch_size):
            batch = texts[i:i + batch_size]
            try:
                # Clean texts
                cleaned_batch = [text.strip() for text in batch if text.strip()]
                
                if not cleaned_batch:
                    # Add zero vectors for empty batch
                    embeddings.extend([[0.0] * self.dimensions] * len(batch))
                    continue
                
                response = self.client.embeddings.create(
                    input=cleaned_batch,
                    model=self.model_name
                )
                
                batch_embeddings = [item.embedding for item in response.data]
                embeddings.extend(batch_embeddings)
                
                logger.info(f"Generated embeddings for batch {i//batch_size + 1}/{(len(texts)-1)//batch_size + 1}")
                
            except Exception as e:
                logger.error(f"Batch embedding generation failed: {e}")
                # Add zero vectors for failed batch
                embeddings.extend([[0.0] * self.dimensions] * len(batch))
        
        return embeddings
    
    def generate_embeddings_with_metadata(
        self, 
        documents: List[Dict[str, Any]]
    ) -> List[Dict[str, Any]]:
        """
        Generate embeddings for documents with metadata.
        
        Args:
            documents: List of documents with 'text' and optional metadata
            
        Returns:
            Documents with added embeddings
        """
        texts = [doc.get('text', '') for doc in documents]
        embeddings = self.generate_embeddings_batch(texts)
        
        # Add embeddings to documents
        for doc, embedding in zip(documents, embeddings):
            doc['embedding'] = embedding
            doc['embedding_model'] = self.model_name
            doc['embedding_dimensions'] = len(embedding)
        
        return documents
    
    def calculate_similarity(
        self, 
        embedding1: List[float], 
        embedding2: List[float],
        method: str = "cosine"
    ) -> float:
        """
        Calculate similarity between two embeddings.
        
        Args:
            embedding1: First embedding vector
            embedding2: Second embedding vector
            method: Similarity method ("cosine", "dot", "euclidean")
            
        Returns:
            Similarity score
        """
        try:
            vec1 = np.array(embedding1)
            vec2 = np.array(embedding2)
            
            if method == "cosine":
                # Cosine similarity
                dot_product = np.dot(vec1, vec2)
                norm1 = np.linalg.norm(vec1)
                norm2 = np.linalg.norm(vec2)
                
                if norm1 == 0 or norm2 == 0:
                    return 0.0
                
                return dot_product / (norm1 * norm2)
            
            elif method == "dot":
                # Dot product
                return np.dot(vec1, vec2)
            
            elif method == "euclidean":
                # Euclidean distance (converted to similarity)
                distance = np.linalg.norm(vec1 - vec2)
                return 1 / (1 + distance)
            
            else:
                logger.error(f"Unknown similarity method: {method}")
                return 0.0
                
        except Exception as e:
            logger.error(f"Similarity calculation failed: {e}")
            return 0.0
    
    def find_most_similar(
        self, 
        query_embedding: List[float], 
        candidate_embeddings: List[List[float]],
        top_k: int = 5,
        threshold: float = 0.0
    ) -> List[Dict[str, Any]]:
        """
        Find most similar embeddings to a query.
        
        Args:
            query_embedding: Query embedding vector
            candidate_embeddings: List of candidate embeddings
            top_k: Number of top similar embeddings to return
            threshold: Minimum similarity threshold
            
        Returns:
            List of similar embeddings with scores and indices
        """
        similarities = []
        
        for i, candidate in enumerate(candidate_embeddings):
            similarity = self.calculate_similarity(query_embedding, candidate)
            if similarity >= threshold:
                similarities.append({
                    'index': i,
                    'similarity': similarity,
                    'embedding': candidate
                })
        
        # Sort by similarity (descending)
        similarities.sort(key=lambda x: x['similarity'], reverse=True)
        
        return similarities[:top_k]
    
    def cluster_embeddings(
        self, 
        embeddings: List[List[float]], 
        n_clusters: int = 5
    ) -> List[int]:
        """
        Cluster embeddings using K-means.
        
        Args:
            embeddings: List of embedding vectors
            n_clusters: Number of clusters
            
        Returns:
            Cluster labels for each embedding
        """
        try:
            from sklearn.cluster import KMeans
            
            embeddings_array = np.array(embeddings)
            kmeans = KMeans(n_clusters=n_clusters, random_state=42)
            cluster_labels = kmeans.fit_predict(embeddings_array)
            
            return cluster_labels.tolist()
            
        except ImportError:
            logger.error("sklearn not available for clustering")
            return [0] * len(embeddings)
        except Exception as e:
            logger.error(f"Clustering failed: {e}")
            return [0] * len(embeddings)
    
    def reduce_dimensions(
        self, 
        embeddings: List[List[float]], 
        target_dims: int = 50
    ) -> List[List[float]]:
        """
        Reduce embedding dimensions using PCA.
        
        Args:
            embeddings: List of embedding vectors
            target_dims: Target number of dimensions
            
        Returns:
            Reduced dimension embeddings
        """
        try:
            from sklearn.decomposition import PCA
            
            embeddings_array = np.array(embeddings)
            pca = PCA(n_components=target_dims)
            reduced_embeddings = pca.fit_transform(embeddings_array)
            
            return reduced_embeddings.tolist()
            
        except ImportError:
            logger.error("sklearn not available for dimensionality reduction")
            return embeddings
        except Exception as e:
            logger.error(f"Dimensionality reduction failed: {e}")
            return embeddings
    
    def get_embedding_stats(self, embeddings: List[List[float]]) -> Dict[str, Any]:
        """
        Get statistics about embeddings.
        
        Args:
            embeddings: List of embedding vectors
            
        Returns:
            Embedding statistics
        """
        if not embeddings:
            return {"count": 0}
        
        embeddings_array = np.array(embeddings)
        
        return {
            "count": len(embeddings),
            "dimensions": embeddings_array.shape[1],
            "mean_norm": np.mean(np.linalg.norm(embeddings_array, axis=1)),
            "std_norm": np.std(np.linalg.norm(embeddings_array, axis=1)),
            "mean_values": np.mean(embeddings_array, axis=0).tolist(),
            "std_values": np.std(embeddings_array, axis=0).tolist()
        }