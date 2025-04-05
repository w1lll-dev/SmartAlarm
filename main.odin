package main

import "core:log"
import ma "vendor:miniaudio"
import sdl "vendor:sdl3"

SCREEN_WIDTH :: 128
SCREEN_HEIGHT :: 160

AUDIO_CHANNELS :: 1
AUDIO_SAMPLE_RATE :: 44100
AUDIO_SAMPLE_SIZE :: 16

// data_callback :: proc "c" (pDevice: ^ma.device, pOutput, pInput: rawptr, frameCount: u32) {
// 	pDecoder := cast(^ma.decoder)pDevice
// 	if pDecoder == nil do return

// 	ma.decoder_read_pcm_frames(pDecoder, pInput, u64(frameCount), nil)
// }

main :: proc() {
	// encoder: ma.encoder
	// encoderConfig := ma.encoder_config_init(.wav, .f32, AUDIO_CHANNELS, AUDIO_SAMPLE_RATE)

	// assert(ma.encoder_init_file("output.wav", &encoderConfig, &encoder) == .SUCCESS)

	// device: ma.device
	// deviceConfig := ma.device_config_init(.capture)
	// deviceConfig.capture.format = .unknown
	// deviceConfig.capture.channels = AUDIO_CHANNELS
	// deviceConfig.sampleRate = AUDIO_SAMPLE_RATE
	// deviceConfig.dataCallback = data_callback
	// deviceConfig.pUserData = &encoder

	// assert(ma.device_init(nil, &deviceConfig, &device) == .SUCCESS)
	context.logger = log.create_console_logger()

	init := sdl.Init({.VIDEO})
	if !init do log.panicf("Could not init SDL", sdl.GetError())
	else do defer sdl.Quit()

	win := sdl.CreateWindow("SmartAlarm", SCREEN_WIDTH, SCREEN_HEIGHT, {})
	if win == nil do log.panicf("Could not create window", sdl.GetError())
	else do defer sdl.DestroyWindow(win)

	gpu := sdl.CreateGPUDevice({.SPIRV}, true, nil)
	if gpu == nil do log.panicf("Could not create GPU device", sdl.GetError())
	else do defer sdl.DestroyGPUDevice(gpu)

	claim := sdl.ClaimWindowForGPUDevice(gpu, win)
	if !claim do log.panicf("Could not claim window for gpu device", sdl.GetError())

	gameLoop: for {
		// process events
		ev: sdl.Event
		for sdl.PollEvent(&ev) {
			#partial switch ev.type {
			case .QUIT:
				break gameLoop
			case .KEY_DOWN:
				if ev.key.scancode == .ESCAPE do break gameLoop
			}
		}

		// update game state


		// render
	}
}

