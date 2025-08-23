"""Simple FastAPI application for GenAI Ops."""

import logging
from typing import Dict, List

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

from .models.azure_openai import GenAIModel

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="Azure GenAI Ops API",
    description="API for Generative AI Operations using Azure services",
    version="0.1.0"
)

# Initialize model
model = GenAIModel()


class TextInput(BaseModel):
    text: str
    max_tokens: int = 1000
    temperature: float = 0.7


class TextOutput(BaseModel):
    result: str


class BatchTextInput(BaseModel):
    texts: List[str]
    max_tokens: int = 1000
    temperature: float = 0.7


class BatchTextOutput(BaseModel):
    results: List[str]


@app.get("/")
async def root():
    """Root endpoint."""
    return {"message": "Azure GenAI Ops API is running"}


@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {"status": "healthy"}


@app.post("/generate", response_model=TextOutput)
async def generate_text(input_data: TextInput):
    """Generate text using the model."""
    try:
        result = model.predict(
            input_data.text,
            max_tokens=input_data.max_tokens,
            temperature=input_data.temperature
        )
        return TextOutput(result=result)
    except Exception as e:
        logger.error(f"Error generating text: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/batch-generate", response_model=BatchTextOutput)
async def batch_generate_text(input_data: BatchTextInput):
    """Generate text for multiple inputs."""
    try:
        results = model.batch_predict(
            input_data.texts,
            max_tokens=input_data.max_tokens,
            temperature=input_data.temperature
        )
        return BatchTextOutput(results=results)
    except Exception as e:
        logger.error(f"Error in batch generation: {e}")
        raise HTTPException(status_code=500, detail=str(e))


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)