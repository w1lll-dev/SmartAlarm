package main

import "core:os"
import ma "vendor:miniaudio"
import rl "vendor:raylib"

SCREEN_WIDTH :: 128
SCREEN_HEIGHT :: 160

AUDIO_CHANNELS :: 1
AUDIO_SAMPLE_RATE :: 44100
AUDIO_SAMPLE_SIZE :: 16

audioBuffer: [dynamic]f32

data_callback :: proc "c" (pDevice: ^ma.device, pOutput, pInput: rawptr, frameCount: u32) {
	pDecoder := cast(^ma.decoder)pDevice
	append(&audioBuffer, ..input[:frameCount * pDevice.capture.channels])
}

main :: proc() {
	rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "timer")
	defer rl.CloseWindow()

	rl.SetTargetFPS(60)

	offset: f32 = 10
	height: f32 = 50

	recs: [dynamic]rl.Rectangle

	result: ma.result

	encoder: ma.encoder
	encoderConfig := ma.encoder_config_init(.wav, .f32, AUDIO_CHANNELS, AUDIO_SAMPLE_RATE)
	ma.encoder_init_file("output.wav", &encoderConfig, &encoder)

	device: ma.device
	deviceConfig := ma.device_config_init(.capture)
	deviceConfig.capture.format = .unknown
	deviceConfig.capture.channels = AUDIO_CHANNELS
	deviceConfig.sampleRate = AUDIO_SAMPLE_RATE
	deviceConfig.dataCallback = data_callback
	deviceConfig.pUserData = &encoder

	if ma.device_init(nil, &deviceConfig, &device) != .SUCCESS {
		os.exit(-1)
	}

	rl.InitAudioDevice()
	defer rl.CloseAudioDevice()
	stream := rl.LoadAudioStream(AUDIO_SAMPLE_RATE, AUDIO_SAMPLE_SIZE, AUDIO_CHANNELS)

	for !rl.WindowShouldClose() {
		if rl.IsKeyPressed(.E) {
			rec: rl.Rectangle = {
				offset,
				offset + f32(len(recs)) * (height + offset),
				SCREEN_WIDTH - offset * 2,
				height,
			}
			append(&recs, rec)
		}

		if rl.IsKeyPressed(.SPACE) && !ma.device_is_started(&device) {
			ma.device_start(&device)
		} else if rl.IsKeyReleased(.SPACE) && ma.device_is_started(&device) {
			ma.device_uninit(&device)
		}

		if len(audioBuffer) > 0 {
			rl.UpdateAudioStream(stream, raw_data(audioBuffer[:]), i32(len(audioBuffer)))
			rl.PlayAudioStream(stream)
			clear(&audioBuffer)
		}

		rl.BeginDrawing()
		defer rl.EndDrawing()

		for i in 0 ..< len(recs) {
			rl.DrawRectangleRec(recs[i], rl.WHITE)
		}
	}
}

