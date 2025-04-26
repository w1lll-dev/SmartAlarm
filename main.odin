package main

import "core:log"
import ma "vendor:miniaudio"
import sdl "vendor:sdl2"

SCREEN_WIDTH :: 128
SCREEN_HEIGHT :: 160

main :: proc() {
	context.logger = log.create_console_logger()

	// Init capture device
	encoder: ma.encoder
	captureDevice: ma.device

	InitCaptureDevice(&encoder, &captureDevice)

	defer ma.encoder_uninit(&encoder)
	defer ma.device_uninit(&captureDevice)

	// Init playback device
	// decoder: ma.decoder
	// playbackDevice: ma.device

	// InitPlaybackDevice(&decoder, &playbackDevice)

	// defer ma.decoder_uninit(&decoder)
	// defer ma.device_uninit(&playbackDevice)

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

	offset: i32 = 10
	height: i32 = 50
	outlineSize: i32 = 2

	rects: [dynamic]sdl.Rect
	selectRect: sdl.Rect = {
		offset - outlineSize,
		offset + i32(len(rects)) * (height + offset) - outlineSize,
		SCREEN_WIDTH - offset * 2 + outlineSize * 2,
		height + outlineSize * 2,
	}
	curRect: i32

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
				// log.debugf("Playing audio...")
				// ma.device_start(&playbackDevice)
				case .E:
					rect: sdl.Rect = {
						offset,
						offset + i32(len(rects)) * (height + offset),
						SCREEN_WIDTH - offset * 2,
						height,
					}
					append(&rects, rect)
				case .DOWN:
					for i in 0 ..< i32(len(rects)) {
						rects[i].y -= height + offset

						if i == curRect do selectRect.y = rects[i].y - outlineSize

					}
					curRect += 1
				case .UP:
					for i in 0 ..< i32(len(rects)) {
						if curRect == 0 do break
						rects[i].y += height + offset
						if i == curRect do selectRect.y = rects[i].y - outlineSize
					}
					curRect -= 1
				}
			case .KEYUP:
				#partial switch ev.key.keysym.sym {
				case .SPACE:
					log.debugf("Stopped Recording.")
					ma.device_stop(&captureDevice)

				case .RETURN:
				// log.debugf("Stopped playing")
				// ma.device_stop(&playbackDevice)
				}
			}
		}

		// Update app state


		// Render
		sdl.SetRenderDrawColor(rend, 0, 0, 0, 255)
		sdl.RenderClear(rend)

		sdl.SetRenderDrawColor(rend, 0, 0, 255, 255)
		sdl.RenderFillRect(rend, &selectRect)

		sdl.SetRenderDrawColor(rend, 255, 255, 255, 255)
		for i in 0 ..< len(rects) {
			sdl.RenderFillRect(rend, &rects[i])
		}

		sdl.RenderPresent(rend)
	}
}

