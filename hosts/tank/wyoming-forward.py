import argparse
import asyncio
import io
import json
import os
import wave
import aiohttp
from wyoming.server import AsyncEventHandler, AsyncServer, partial
from wyoming.event import Event
from wyoming.audio import AudioChunk, AudioStop
from wyoming.asr import Transcribe, Transcript
from wyoming.info import Describe, Info
from wyoming.info import AsrModel, AsrProgram, Attribution, Info

parser = argparse.ArgumentParser(description="Wyoming Forward to OpenAI API")
parser.add_argument("--wyoming-uri", type=str, default="tcp://0.0.0.0:3001")
parser.add_argument("--model", type=str, default="whisper-1")
parser.add_argument("--language", type=str, default=None)
args = parser.parse_args()

OPENAI_BASE_URL = os.environ.get("OPENAI_BASE_URL", "https://api.openai.com/v1")
OPENAI_API_KEY = os.environ.get("OPENAI_API_KEY", "")
if not OPENAI_API_KEY:
    print(
        "[Warning] OPENAI_API_KEY is not set. You may need to set it if you are not self-hosting Whisper"
    )


class Handler(AsyncEventHandler):
    file_obj: io.BytesIO | None = None
    wav_file: wave.Wave_write | None = None
    lang: str | None = None

    async def handle_event(self, event: Event) -> bool:
        if AudioChunk.is_type(event.type):
            chunk = AudioChunk.from_event(event)

            if self.wav_file is None:
                print("AudioChunk begin")
                self.file_obj = io.BytesIO()
                self.wav_file = wave.open(self.file_obj, "wb")
                self.wav_file.setframerate(chunk.rate)
                self.wav_file.setsampwidth(chunk.width)
                self.wav_file.setnchannels(chunk.channels)

            self.wav_file.writeframes(chunk.audio)
            return True

        if AudioStop.is_type(event.type):
            print("AudioStop")
            assert self.wav_file is not None
            assert self.file_obj is not None
            self.wav_file.close()
            self.wav_file = None
            self.file_obj.seek(0)

            lang = self.lang or args.language
            form = aiohttp.FormData()
            form.add_field("file", self.file_obj, filename="audio.wav")
            form.add_field("model", args.model)
            form.add_field("response_format", "text")
            if lang:
                form.add_field("language", lang)
            async with aiohttp.ClientSession() as session:
                async with session.post(
                    f"{OPENAI_BASE_URL}/audio/transcriptions",
                    headers={"Authorization": f"Bearer {OPENAI_API_KEY}"},
                    data=form,
                ) as resp:
                    assert resp.status == 200
                    raw = await resp.text()
                    try:
                        text = json.loads(raw).get("text", raw)
                    except (json.JSONDecodeError, AttributeError):
                        text = raw
                    print(text)
                    await self.write_event(Transcript(text=text).event())
            self.lang = None
            return False

        if Transcribe.is_type(event.type):
            print("Transcribe")
            transcribe = Transcribe.from_event(event)
            if transcribe.language:
                self.lang = transcribe.language

            return True

        if Describe.is_type(event.type):
            print("Describe")
            await self.write_event(
                Info(
                    asr=[
                        AsrProgram(
                            name="whisper-forward",
                            description="Whisper forward to OpenAI API endpoint",
                            attribution=Attribution(
                                name="heimoshuiyu",
                                url="https://github.com/heimoshuiyu/whisper-fastapi",
                            ),
                            installed=True,
                            version="0.1",
                            models=[
                                AsrModel(
                                    name=args.model,
                                    description=args.model,
                                    attribution=Attribution(
                                        name="Systran",
                                        url="https://huggingface.co/Systran",
                                    ),
                                    installed=True,
                                    languages=_LANGUAGE_CODES,
                                    version="0.1",
                                )
                            ],
                        )
                    ],
                ).event()
            )
            return True

        return True


_LANGUAGE_CODES = [
    "af", "am", "ar", "as", "az", "ba", "be", "bg", "bn", "bo", "br", "bs", "ca", "cs",
    "cy", "da", "de", "el", "en", "es", "et", "eu", "fa", "fi", "fo", "fr", "gl", "gu",
    "ha", "haw", "he", "hi", "hr", "ht", "hu", "hy", "id", "is", "it", "ja", "jw", "ka",
    "kk", "km", "kn", "ko", "la", "lb", "ln", "lo", "lt", "lv", "mg", "mi", "mk", "ml",
    "mn", "mr", "ms", "mt", "my", "ne", "nl", "nn", "no", "oc", "pa", "pl", "ps", "pt",
    "ro", "ru", "sa", "sd", "si", "sk", "sl", "sn", "so", "sq", "sr", "su", "sv", "sw",
    "ta", "te", "tg", "th", "tk", "tl", "tr", "tt", "uk", "ur", "uz", "vi", "yi", "yo",
    "zh", "yue",
]


async def wyoming_server(uri: str):
    server = AsyncServer.from_uri(uri)
    print(f"Running wyoming server on {uri}")
    await server.run(partial(Handler))


if __name__ == "__main__":
    asyncio.run(wyoming_server(args.wyoming_uri))
