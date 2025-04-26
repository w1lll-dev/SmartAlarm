package main

import ma "vendor:miniaudio"

AUDIO_FORMAT :: ma.format.f32
AUDIO_CHANNELS :: 2
AUDIO_SAMPLE_RATE :: 44100
AUDIO_FILE :: "output.wav"

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

	assert(ma.encoder_init_file(AUDIO_FILE, &encoderConfig, encoder) == .SUCCESS)

	deviceConfig := ma.device_config_init(.capture)
	deviceConfig.capture.format = AUDIO_FORMAT
	deviceConfig.capture.channels = AUDIO_CHANNELS
	deviceConfig.sampleRate = AUDIO_SAMPLE_RATE
	deviceConfig.dataCallback = CaptureDataCallback
	deviceConfig.pUserData = encoder

	assert(ma.device_init(nil, &deviceConfig, device) == .SUCCESS)
}

InitPlaybackDevice :: proc(decoder: ^ma.decoder, device: ^ma.device) {
	assert(ma.decoder_init_file(AUDIO_FILE, nil, decoder) == .SUCCESS)

	deviceConfig := ma.device_config_init(.playback)
	deviceConfig.playback.format = AUDIO_FORMAT
	deviceConfig.playback.channels = AUDIO_CHANNELS
	deviceConfig.sampleRate = AUDIO_SAMPLE_RATE
	deviceConfig.dataCallback = PlaybackDataCallback
	deviceConfig.pUserData = decoder

	assert(ma.device_init(nil, &deviceConfig, device) == .SUCCESS)
}

