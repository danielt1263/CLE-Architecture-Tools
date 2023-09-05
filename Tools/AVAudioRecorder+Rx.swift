//
//  AVAudioRecorder.swift
//
//  Created by Daniel Tartaglia on 26 May 2022.
//  Copyright © 2022 Daniel Tartaglia. MIT License.
//

import AVKit
import Foundation
import RxResource
import RxSwift

func audioRecorderSession(
	url: URL,
	settings: [String: Any],
	command: Observable<AudioRecorderCommand>
) -> Observable<TimeInterval> {
	Observable.using(
		Resource.build(
			try AVAudioRecorder(url: url, settings: settings),
			dispose: { _ in }
		),
		observableFactory: Resource.createObservable { disposeBag, audioRecorder in
			audioRecorder.record()
			command
				.subscribe(onNext: { command in
					switch command {
					case .delete:
						audioRecorder.deleteRecording()
					case .stop:
						audioRecorder.stop()
					}
				})
				.disposed(by: disposeBag)

			return Observable<Int>.interval(.milliseconds(100), scheduler: MainScheduler.instance)
				.flatMap { _ in
					Observable.just(audioRecorder.currentTime)
				}
				.distinctUntilChanged()
		}
	)
}

enum AudioRecorderCommand {
	case delete
	case stop
}
