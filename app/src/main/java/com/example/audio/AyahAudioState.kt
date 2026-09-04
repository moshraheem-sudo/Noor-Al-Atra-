package com.example.audio

object AyahAudioState {
    var manager: AudioPlayerManager? = null
    
    fun togglePlayPause() { manager?.togglePlayPause() }
    fun playNext() { manager?.playNext() }
    fun playPrev() { manager?.playPrev() }
    fun stop() { manager?.stop() }
}
