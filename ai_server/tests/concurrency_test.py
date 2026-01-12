import asyncio
import aiohttp
import time
import os


# Create a dummy image for testing
def create_dummy_image():
    from PIL import Image
    import io

    img = Image.new("RGB", (100, 100), color="red")
    byte_arr = io.BytesIO()
    img.save(byte_arr, format="JPEG")
    return byte_arr.getvalue()


async def send_request(session, url, image_data, i):
    print(f"Request {i} started")
    start_time = time.time()
    data = aiohttp.FormData()
    data.add_field("file", image_data, filename="test.jpg", content_type="image/jpeg")

    try:
        async with session.post(url, data=data) as response:
            await response.read()
            end_time = time.time()
            print(
                f"Request {i} finished in {end_time - start_time:.2f}s, Status: {response.status}"
            )
            return response.status
    except Exception as e:
        print(f"Request {i} failed: {e}")
        return 0


async def main():
    # Note: This test assumes the server is running on localhost:8000
    url = "http://localhost:8000/upscale"
    image_data = create_dummy_image()

    async with aiohttp.ClientSession() as session:
        tasks = [send_request(session, url, image_data, i) for i in range(3)]
        await asyncio.gather(*tasks)


if __name__ == "__main__":
    print(
        "To run this test, start the server with: uvicorn main:app --host 0.0.0.0 --port 8000"
    )
    print("Then run: python3 tests/concurrency_test.py")

    try:
        asyncio.run(main())
    except Exception as e:
        print(f"Test skipped/failed (Server likely down): {e}")
