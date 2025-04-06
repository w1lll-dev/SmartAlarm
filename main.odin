package main

import "core:log"
import ma "vendor:miniaudio"
import sdl "vendor:sdl2"

SCREEN_WIDTH :: 128
SCREEN_HEIGHT :: 160

AUDIO_FORMAT :: ma.format.f32
AUDIO_CHANNELS :: 2
AUDIO_SAMPLE_RATE :: 44100
AUDIO_OUTPUT_FILE :: "output.wav"

CaptureDataCallback :: proc "c" (pDevice: ^ma.device, pOutput, pInput: rawptr, frameCount: u32) {
	pEncoder := cast(^ma.encoder)pDevice.pUserData
	if pEncoder == nil do return

	ma.encoder_write_pcm_frames(pEncoder, pInput, u64(frameCount), nil)
}

PlaybackDataCallback :: proc "c" (pDevice: ^ma.device, pOutput, pInput: rawptr, frameCount: u32) {
	pDecoder := cast(^ma.decoder)pDevice.pUserData
	if pDecoder == nil do return

	ma.decoder_read_pcm_frames(pDecoder, pOutput, u64(frameCount), nil)
}

InitCaptureDevice :: proc(encoder: ^ma.encoder, device: ^ma.device) {
	encoderConfig := ma.encoder_config_init(.wav, AUDIO_FORMAT, AUDIO_CHANNELS, AUDIO_SAMPLE_RATE)

	assert(ma.encoder_init_file(AUDIO_OUTPUT_FILE, &encoderConfig, encoder) == .SUCCESS)

	deviceConfig := ma.device_config_init(.capture)
	deviceConfig.capture.format = AUDIO_FORMAT
	deviceConfig.capture.channels = AUDIO_CHANNELS
	deviceConfig.sampleRate = AUDIO_SAMPLE_RATE
	deviceConfig.dataCallback = CaptureDataCallback
	deviceConfig.pUserData = encoder

	assert(ma.device_init(nil, &deviceConfig, device) == .SUCCESS)
}

InitPlaybackDevice :: proc(decoder: ^ma.decoder, device: ^ma.device) {
	assert(ma.decoder_init_file(AUDIO_OUTPUT_FILE, nil, decoder) == .SUCCESS)

	deviceConfig := ma.device_config_init(.playback)
	deviceConfig.playback.format = AUDIO_FORMAT
	deviceConfig.playback.channels = AUDIO_CHANNELS
	deviceConfig.sampleRate = AUDIO_SAMPLE_RATE
	deviceConfig.dataCallback = PlaybackDataCallback
	deviceConfig.pUserData = decoder

	assert(ma.device_init(nil, &deviceConfig, device) == .SUCCESS)
}

main :: proc() {
	context.logger = log.create_console_logger()

	// Init capture device
	encoder: ma.encoder
	captureDevice: ma.device

	InitCaptureDevice(&encoder, &captureDevice)

	defer ma.encoder_uninit(&encoder)
	defer ma.device_uninit(&captureDevice)

	decoder: ma.decoder
	playbackDevice: ma.device

	// Init SDL
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

	mainLoop: for {
		// Process events
		ev: sdl.Event
		for sdl.PollEvent(&ev) {
			#partial switch ev.type {
			case .QUIT:
				break mainLoop
			case .KEYDOWN:
				if ev.key.keysym.sym == .ESCAPE do break mainLoop

				if ev.key.repeat > 0 do break

				#partial switch ev.key.keysym.sym {
				case .SPACE:
					log.debugf("Recording...")
					ma.device_start(&captureDevice)
				case .RETURN:
					// Init playback device

					InitPlaybackDevice(&decoder, &playbackDevice)

					defer ma.decoder_uninit(&decoder)
					defer ma.device_uninit(&playbackDevice)
					log.debugf("Playing audio...")
					ma.device_start(&playbackDevice)
				}
			case .KEYUP:
				#partial switch ev.key.keysym.sym {
				case .SPACE:
					log.debugf("Stopped Recording.")
					ma.device_stop(&captureDevice)
				case .RETURN:
					log.debugf("Stopped playing")
					ma.device_stop(&playbackDevice)
				}
			}
		}

		// Update app state


		// Render
		sdl.SetRenderDrawColor(rend, 0, 0, 0, 255)
		sdl.RenderClear(rend)
		sdl.RenderPresent(rend)
	}
}

