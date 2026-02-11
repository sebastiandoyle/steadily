#!/usr/bin/env python3
"""Generate marketing screenshots for Steadily app."""

from PIL import Image, ImageDraw, ImageFont
import os

# Dimensions for App Store
IPHONE_WIDTH = 1290
IPHONE_HEIGHT = 2796

# Brand colors
SAGE_GREEN = (125, 155, 118)  # #7D9B76
WARM_CREAM = (253, 248, 243)  # #FDF8F3
DEEP_FOREST = (45, 71, 57)    # #2D4739
SOFT_TERRACOTTA = (212, 165, 116)  # #D4A574

# Screenshot data with headlines
SCREENSHOTS = [
    {
        "source": "today.png",
        "output": "1_6.5_inch.png",
        "headline": "Progress Without Pressure",
        "subheadline": "Build habits that work with your life"
    },
    {
        "source": "habits.png",
        "output": "2_6.5_inch.png",
        "headline": "Miss a Day? Still on Track",
        "subheadline": "Streaks that bend without breaking"
    },
    {
        "source": "insights.png",
        "output": "3_6.5_inch.png",
        "headline": "See How Far You've Come",
        "subheadline": "Progress you can feel, not just count"
    },
    {
        "source": "paywall.png",
        "output": "4_6.5_inch.png",
        "headline": "Unlock Your Full Potential",
        "subheadline": "Premium features for serious growth"
    },
    {
        "source": "onboarding.png",
        "output": "5_6.5_inch.png",
        "headline": "30 Seconds. Done.",
        "subheadline": "Designed for busy days and distracted brains"
    }
]

def create_gradient_background(width, height):
    """Create a gradient background from sage green to warm cream."""
    img = Image.new('RGB', (width, height))
    draw = ImageDraw.Draw(img)

    for y in range(height):
        ratio = y / height
        r = int(SAGE_GREEN[0] * (1 - ratio) + WARM_CREAM[0] * ratio)
        g = int(SAGE_GREEN[1] * (1 - ratio) + WARM_CREAM[1] * ratio)
        b = int(SAGE_GREEN[2] * (1 - ratio) + WARM_CREAM[2] * ratio)
        draw.line([(0, y), (width, y)], fill=(r, g, b))

    return img

def add_text(draw, text, y_position, font_size, color, width, bold=False):
    """Add centered text to the image."""
    try:
        if bold:
            font = ImageFont.truetype("/System/Library/Fonts/SFNS.ttf", font_size)
        else:
            font = ImageFont.truetype("/System/Library/Fonts/SFNS.ttf", font_size)
    except:
        try:
            font = ImageFont.truetype("/Library/Fonts/Arial Bold.ttf" if bold else "/Library/Fonts/Arial.ttf", font_size)
        except:
            font = ImageFont.load_default()

    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    x = (width - text_width) // 2
    draw.text((x, y_position), text, fill=color, font=font)

def process_screenshot(source_path, output_path, headline, subheadline):
    """Process a screenshot into a marketing image."""
    # Create gradient background
    background = create_gradient_background(IPHONE_WIDTH, IPHONE_HEIGHT)
    draw = ImageDraw.Draw(background)

    # Add headline text
    add_text(draw, headline, 120, 72, DEEP_FOREST, IPHONE_WIDTH, bold=True)

    # Add subheadline text
    add_text(draw, subheadline, 210, 42, SAGE_GREEN, IPHONE_WIDTH)

    # Load and resize screenshot
    screenshot = Image.open(source_path)

    # Calculate dimensions to fit screenshot
    target_width = int(IPHONE_WIDTH * 0.85)
    aspect_ratio = screenshot.height / screenshot.width
    target_height = int(target_width * aspect_ratio)

    # Limit height to fit
    max_height = IPHONE_HEIGHT - 380
    if target_height > max_height:
        target_height = max_height
        target_width = int(target_height / aspect_ratio)

    screenshot = screenshot.resize((target_width, target_height), Image.Resampling.LANCZOS)

    # Center the screenshot
    x_offset = (IPHONE_WIDTH - target_width) // 2
    y_offset = 320

    # Add rounded corners effect with shadow
    # Paste screenshot
    background.paste(screenshot, (x_offset, y_offset))

    # Save
    background.save(output_path, "PNG")
    print(f"Created: {output_path}")

def main():
    base_dir = "/Users/sebastiandoyle/Developer/Steadily"
    source_dir = os.path.join(base_dir, "screenshots")
    output_dir = os.path.join(base_dir, "fastlane", "screenshots", "en-AU")

    os.makedirs(output_dir, exist_ok=True)

    for screenshot in SCREENSHOTS:
        source_path = os.path.join(source_dir, screenshot["source"])
        output_path = os.path.join(output_dir, screenshot["output"])

        if os.path.exists(source_path):
            process_screenshot(
                source_path,
                output_path,
                screenshot["headline"],
                screenshot["subheadline"]
            )
        else:
            print(f"Warning: Source not found: {source_path}")

if __name__ == "__main__":
    main()
