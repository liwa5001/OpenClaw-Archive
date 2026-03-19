#!/usr/bin/env python3
"""
DALL-E 3 Image Generator
Usage: python3 generate-dalle3-image.py --prompt "your prompt" --output "filename.png"
"""

import argparse
import os
import sys
from datetime import datetime

try:
    from openai import OpenAI
except ImportError:
    print("Error: openai library not installed. Run: pip3 install openai")
    sys.exit(1)

def generate_image(prompt, output_path, size="1024x1024", quality="standard"):
    """Generate image using DALL-E 3"""
    
    # Get API key from environment or argument
    api_key = os.environ.get('OPENAI_API_KEY')
    if not api_key:
        print("Error: OPENAI_API_KEY environment variable not set")
        print("Please set it: export OPENAI_API_KEY='your-key-here'")
        sys.exit(1)
    
    client = OpenAI(api_key=api_key)
    
    print(f"🎨 Generating image with DALL-E 3...")
    print(f"📝 Prompt: {prompt[:100]}...")
    
    try:
        response = client.images.generate(
            model="dall-e-3",
            prompt=prompt,
            size=size,
            quality=quality,
            n=1,
        )
        
        image_url = response.data[0].url
        print(f"✅ Image generated! Downloading...")
        
        # Download image
        import requests
        img_data = requests.get(image_url).content
        
        with open(output_path, 'wb') as handler:
            handler.write(img_data)
        
        print(f"💾 Image saved to: {os.path.abspath(output_path)}")
        return output_path
        
    except Exception as e:
        print(f"❌ Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Generate images with DALL-E 3')
    parser.add_argument('--prompt', required=True, help='Image description')
    parser.add_argument('--output', required=True, help='Output filename')
    parser.add_argument('--size', default='1024x1024', choices=['1024x1024', '1792x1024', '1024x1792'], help='Image size')
    parser.add_argument('--quality', default='standard', choices=['standard', 'hd'], help='Image quality')
    
    args = parser.parse_args()
    generate_image(args.prompt, args.output, args.size, args.quality)
