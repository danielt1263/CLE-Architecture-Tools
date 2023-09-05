//
//  AVAudioPlayer.swift
//
//  Created by Daniel Tartaglia on 26 May 2022.
//  Copyright © 2022 Daniel Tartaglia. MIT License.
//

import AVKit
import Foundation
import RxResource
import RxSwift

func audioPlayerSession(url: URL, togglePlay: Observable<Void>) -> Observable<AudioPlayerState> {
	Observable.using(
		Resource.build(
			try AVAudioPlayer(contentsOf: url),
			dispose: { $0.stop() }
		),
		observableFactory: Resource.createObservable { disposeBag, audioPlayer in
			togglePlay
				.subscribe(onNext: audioPlayer.toggle)
				.disposed(by: disposeBag)
			return Observable<Int>.interval(.milliseconds(100), scheduler: MainScheduler.instance)
				.map(to: ())
				.flatMap { Observable.just(audioPlayer.playerState()) }
				.distinctUntilChanged()
		}
	)
}

struct AudioPlayerState: Equatable {
	enum Activity: Equatable {
		case stopped
		case playing
		case paused
	}

	let currentTime: TimeInterval
	let duration: TimeInterval
	let activity: Activity
}

private extension AVAudioPlayer {
	func toggle() {
		if isPlaying { pause() }
		else { play() }
	}

	var isPaused: Bool {
		return !isPlaying && currentTime > 0
	}

	func playerState() -> AudioPlayerState {
		AudioPlayerState(
			currentTime: currentTime,
			duration: duration,
			activity: isPlaying ? .playing : isPaused ? .paused : .stopped
		)
	}
}
