package main

import "core:log"
import ma "vendor:miniaudio"
import sdl "vendor:sdl2"

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

	assert(sdl.Init(sdl.INIT_VIDEO) == 0, sdl.GetErrorString())
	defer sdl.Quit()

	win := sdl.CreateWindow(
		"SmartAlarm",
		sdl.WINDOWPOS_CENTERED,
		sdl.WINDOWPOS_CENTERED,
		SCREEN_WIDTH,
		SCREEN_HEIGHT,
		sdl.WINDOW_SHOWN,
	)
	assert(win != nil, sdl.GetErrorString())
	defer sdl.DestroyWindow(win)

	rend := sdl.CreateRenderer(win, -1, sdl.RENDERER_SOFTWARE)
	assert(rend != nil, sdl.GetErrorString())
	defer sdl.DestroyRenderer(rend)

	gameLoop: for {
		ev: sdl.Event
		for sdl.PollEvent(&ev) {
			#partial switch ev.type {
			case .QUIT:
				return
			case .KEYDOWN:
				if ev.key.keysym.scancode == sdl.SCANCODE_ESCAPE do return
			}
		}
	}
}

