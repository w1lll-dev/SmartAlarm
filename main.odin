package main

import "core:log"
import "core:math/ease"
import sdl "vendor:sdl2"
import sdlImg "vendor:sdl2/image"
import sdlFont "vendor:sdl2/ttf"

SCREEN_WIDTH :: 128
SCREEN_HEIGHT :: 160

RECT_HEIGHT :: 45
RECT_OFFSET :: 5
RECT_OUTLINE :: 2

animVal: [dynamic]^i32
animFrom: [dynamic]i32
animTo: [dynamic]i32

anim := false
del := false

Alarm :: struct {
	rect:     sdl.Rect,
	icon:     ^sdl.Texture,
	iconRect: sdl.Rect,
	hrRect:   sdl.Rect,
	minRect:  sdl.Rect,
	hrTex:    ^sdl.Texture,
	minTex:   ^sdl.Texture,
}

main :: proc() {
	context.logger = log.create_console_logger()

	// Init SDL
	assert(sdl.Init(sdl.INIT_VIDEO) == 0, sdl.GetErrorString())
	defer sdl.Quit()

	assert(sdlImg.Init(sdlImg.INIT_PNG) != nil, sdl.GetErrorString())
	defer sdlImg.Quit()

	assert(sdlFont.Init() == 0, sdl.GetErrorString())
	defer sdlFont.Quit()

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

	font := sdlFont.OpenFont("JetBrainsMono-SemiBold.ttf", 12)

	txtCol: sdl.Color = {255, 255, 255, 255}

	alarms: [dynamic]Alarm
	curRect: i32

	alarmSelectRect: sdl.Rect

	bgRect: sdl.Rect
	micRect: sdl.Rect

	imgWidth, imgHeight: i32
	micTex := sdlImg.LoadTexture(rend, "mic.png")
	assert(micTex != nil, sdl.GetErrorString())

	sdl.QueryTexture(micTex, nil, nil, &imgWidth, &imgHeight)
	defer sdl.DestroyTexture(micTex)

	lastTicks := sdl.GetTicks()

	elapsedTime: f32 = 0
	animTime: f32 = 250

	mainLoop: for {
		// Process events
		rectAmt := i32(len(alarms))

		ev: sdl.Event
		for sdl.PollEvent(&ev) {
			if anim do break

			#partial switch ev.type {
			case .QUIT:
				break mainLoop
			case .KEYDOWN:
				if ev.key.repeat > 0 do break

				#partial switch ev.key.keysym.sym {
				case .ESCAPE:
					break mainLoop
				case .SPACE:
					bgRect = {
						RECT_OFFSET,
						RECT_OFFSET,
						SCREEN_WIDTH - RECT_OFFSET * 2,
						SCREEN_HEIGHT - RECT_OFFSET * 2,
					}

					micRect = {
						SCREEN_WIDTH / 2 - imgWidth / 2,
						SCREEN_HEIGHT / 2 - imgHeight / 2,
						imgWidth,
						imgHeight,
					}
				case .DOWN:
					if curRect == rectAmt - 1 do break

					if curRect == 0 || curRect == rectAmt - 2 {
						curRect += 1
						MoveSelectionDown(&alarmSelectRect)
					} else {
						curRect += 1
						MoveDown(&alarms)
					}
				case .UP:
					if curRect == 0 do break

					if curRect == 1 || curRect == rectAmt - 1 {
						curRect -= 1
						MoveSelectionUp(&alarmSelectRect)
					} else {
						curRect -= 1
						MoveUp(&alarms)
					}
				case .BACKSPACE:
					DeleteSelection(curRect, &alarmSelectRect, &alarms)
				}
			case .KEYUP:
				#partial switch ev.key.keysym.sym {
				case .SPACE:
					bgRect = {0, 0, 0, 0}
					micRect = {0, 0, 0, 0}

					if rectAmt == 0 {
						alarmSelectRect = {
							RECT_OFFSET - RECT_OUTLINE,
							RECT_OFFSET + rectAmt * (RECT_HEIGHT + RECT_OFFSET) - RECT_OUTLINE,
							SCREEN_WIDTH - RECT_OFFSET * 2 + RECT_OUTLINE * 2,
							RECT_HEIGHT + RECT_OUTLINE * 2,
						}
					}

					rect: sdl.Rect = {
						RECT_OFFSET,
						RECT_OFFSET + rectAmt * (RECT_HEIGHT + RECT_OFFSET),
						SCREEN_WIDTH - RECT_OFFSET * 2,
						RECT_HEIGHT,
					}
					iconRect: sdl.Rect = {
						RECT_OFFSET * 2,
						RECT_OFFSET + rectAmt * (RECT_HEIGHT + RECT_OFFSET) + imgHeight / 8,
						imgWidth / 4,
						imgHeight / 4,
					}

					hrSurface := sdlFont.RenderText_Solid(font, "24", txtCol)
					minSurface := sdlFont.RenderText_Solid(font, "00", txtCol)

					hrRect: sdl.Rect = {
						RECT_OFFSET * 2 + imgWidth / 8,
						RECT_OFFSET + rectAmt * (RECT_HEIGHT + RECT_OFFSET) + imgHeight / 8,
						0,
						0,
					}
					minRect: sdl.Rect = {
						RECT_OFFSET * 2 + imgWidth / 8,
						RECT_OFFSET + rectAmt * (RECT_HEIGHT + RECT_OFFSET) + imgHeight / 8 * 2,
						0,
						0,
					}

					hrTex := sdl.CreateTextureFromSurface(rend, hrSurface)
					minTex := sdl.CreateTextureFromSurface(rend, minSurface)

					alarm: Alarm = {rect, micTex, iconRect, hrRect, minRect, hrTex, minTex}

					append(&alarms, alarm)

					if rectAmt > 1 && curRect == rectAmt - 1 {
						MoveSelectionUp(&alarmSelectRect)
						MoveDown(&alarms)
					}
				}
			}
		}

		// Update app state
		curTicks := sdl.GetTicks()
		deltaTime := curTicks - lastTicks
		lastTicks = curTicks

		if anim && elapsedTime < animTime {
			elapsedTime += f32(deltaTime)

			for i in 0 ..< len(animVal) {
				t := ease.cubic_out(elapsedTime / animTime)
				animVal[i]^ = i32(f32(animFrom[i]) + f32(animTo[i] - animFrom[i]) * t)
			}
		} else if anim && elapsedTime >= animTime {
			if del {
				ordered_remove(&alarms, curRect)
				del = false
			}

			for i in 0 ..< len(animVal) {
				animVal[i]^ = animTo[i]
			}

			clear(&animVal)
			clear(&animFrom)
			clear(&animTo)

			elapsedTime = 0
			anim = false
		}

		// Render
		sdl.SetRenderDrawColor(rend, 10, 15, 20, 255)
		sdl.RenderClear(rend)

		sdl.SetRenderDrawColor(rend, 120, 150, 255, 255)
		sdl.RenderFillRect(rend, &alarmSelectRect)

		sdl.SetRenderDrawColor(rend, 40, 40, 50, 255)
		for i in 0 ..< len(alarms) {
			sdl.RenderFillRect(rend, &alarms[i].rect)

			sdl.RenderCopy(rend, alarms[i].icon, nil, &alarms[i].iconRect)

			sdl.RenderCopy(rend, alarms[i].hrTex, nil, &alarms[i].hrRect)
			sdl.RenderCopy(rend, alarms[i].minTex, nil, &alarms[i].minRect)
		}

		sdl.SetRenderDrawColor(rend, 50, 50, 60, 255)
		sdl.RenderFillRect(rend, &bgRect)

		sdl.RenderCopy(rend, micTex, nil, &micRect)

		sdl.RenderPresent(rend)
	}
}

MoveDown :: proc(alarms: ^[dynamic]Alarm) {
	for i in 0 ..< i32(len(alarms)) {
		Animate(
			&alarms[i].rect.y,
			alarms[i].rect.y,
			alarms[i].rect.y - (RECT_HEIGHT + RECT_OFFSET),
		)
		Animate(
			&alarms[i].iconRect.y,
			alarms[i].iconRect.y,
			alarms[i].iconRect.y - (RECT_HEIGHT + RECT_OFFSET),
		)
	}
}

MoveUp :: proc(alarms: ^[dynamic]Alarm) {
	for i in 0 ..< i32(len(alarms)) {
		Animate(
			&alarms[i].rect.y,
			alarms[i].rect.y,
			alarms[i].rect.y + (RECT_HEIGHT + RECT_OFFSET),
		)
		Animate(
			&alarms[i].iconRect.y,
			alarms[i].iconRect.y,
			alarms[i].iconRect.y + (RECT_HEIGHT + RECT_OFFSET),
		)
	}
}

MoveSelectionDown :: proc(alarmSelectRect: ^sdl.Rect) {
	Animate(&alarmSelectRect.y, alarmSelectRect.y, alarmSelectRect.y + (RECT_HEIGHT + RECT_OFFSET))
}

MoveSelectionUp :: proc(alarmSelectRect: ^sdl.Rect) {
	Animate(&alarmSelectRect.y, alarmSelectRect.y, alarmSelectRect.y - (RECT_HEIGHT + RECT_OFFSET))
}

DeleteSelection :: proc(curRect: i32, alarmSelectRect: ^sdl.Rect, alarms: ^[dynamic]Alarm) {
	del = true

	rectAmt := i32(len(alarms))

	for i in curRect + 1 ..< rectAmt {
		Animate(
			&alarms[i].rect.y,
			alarms[i].rect.y,
			alarms[i].rect.y - (RECT_HEIGHT + RECT_OFFSET),
		)
	}

	if rectAmt == 0 do alarmSelectRect^ = {0, 0, 0, 0}
}

Animate :: proc(val: ^i32, from, to: i32) {
	anim = true
	append(&animVal, val)
	append(&animFrom, from)
	append(&animTo, to)
}

