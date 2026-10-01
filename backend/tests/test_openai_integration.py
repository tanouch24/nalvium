import os
import io
import pytest
from PIL import Image

pytestmark = pytest.mark.skipif(not (os.getenv("OPENAI_API_KEY") and os.getenv("NALVIUM_RUN_OPENAI_INTEGRATION") == "1"), reason="OpenAI integration disabled by default")

def test_real_openai_image_structured_output():
    from app.ai import OpenAIMultimodalProvider
    image = io.BytesIO()
    Image.new("RGB", (32, 32), (20, 120, 90)).save(image, format="JPEG")
    result = OpenAIMultimodalProvider().analyze("Observe cette image et reste prudent.", media_name="integration-test.jpg", image_bytes=image.getvalue())
    assert result.category
    assert result.next_action.type.value in {"request_photo", "ask_question", "instruction", "verify", "safety_stop", "recommend_professional", "resolved"}
