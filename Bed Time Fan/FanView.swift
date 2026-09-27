//
//  FanView.swift
//  Bed Time Fan
//
//  Created by Pawan Sharma on 27/09/26.
//

import SwiftUI
import AVFoundation

struct FanView: View {

    @State private var selectedSpeed = 0
    @State private var fanAngle: Double = 0

    @State private var animationTask: Task<Void, Never>?

    @State private var fanSound: AVAudioPlayer?
    @State private var buttonSound: AVAudioPlayer?
    @State private var offSound: AVAudioPlayer?

    // Original UIKit values
    private let speedRotation: [Double] = [
        0,
        10, // Speed 1
        11, // Speed 2
        12, // Speed 3
        13, // Speed 4
        14, // Speed 5
        15  // Speed 6
    ]

    private let speedInterval: [Double] = [
        0,
        1.0 / 20.0, // Speed 1
        1.0 / 25.0, // Speed 2
        1.0 / 30.0, // Speed 3
        1.0 / 35.0, // Speed 4
        1.0 / 40.0, // Speed 5
        1.0 / 45.0  // Speed 6
    ]

    var body: some View {

        ZStack {

            Color.white
                .ignoresSafeArea()

            VStack(spacing: 30) {

                Spacer()

                // FAN
                Image("fan_1")
                    .resizable()
                    .scaledToFit()
                    .frame(
                        width: 300,
                        height: 300
                    )
                    .rotationEffect(
                        .degrees(fanAngle)
                    )

                Text(
                    selectedSpeed == 0
                    ? "FAN OFF"
                    : "SPEED \(selectedSpeed)"
                )
                .foregroundColor(.white)
                .font(.title2)
                .fontWeight(.bold)

                Spacer()

                // BUTTONS
                HStack(spacing: 8) {

                    ForEach(1...6, id: \.self) { speed in

                        Button {

                            speedButtonPressed(speed)

                        } label: {

                            VStack {

                                Image(systemName: "power")

                                Text("\(speed)")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .frame(
                                width: 55,
                                height: 65
                            )
                            .background(
                                selectedSpeed >= speed
                                ? Color.green
                                : Color.gray.opacity(0.4)
                            )
                            .cornerRadius(10)
                        }
                    }
                }

                Spacer()
            }
            .padding()
        }
        .onDisappear {

            stopFanImmediately()
        }
    }

    // MARK: - BUTTON

    private func speedButtonPressed(_ speed: Int) {

        playButtonSound()

        if selectedSpeed == speed {

            stopFan()

        } else {

            selectedSpeed = speed

            startFan(speed)
        }
    }

    // MARK: - START FAN

    private func startFan(_ speed: Int) {

        animationTask?.cancel()

        playFanSound()

        let increment = speedRotation[speed]
        let interval = speedInterval[speed]

        animationTask = Task {

            while !Task.isCancelled {

                await MainActor.run {

                    fanAngle += increment

                    if fanAngle >= 360 {

                        fanAngle -= 360
                    }
                }

                // Same timing concept as original Timer
                try? await Task.sleep(
                    nanoseconds:
                        UInt64(interval * 1_000_000_000)
                )
            }
        }
    }

    // MARK: - STOP FAN

    private func stopFan() {

        animationTask?.cancel()
        animationTask = nil

        fanSound?.stop()

        playOffFanSound()

        // Original application has a slow stopping effect.
        slowStopAnimation()
    }

    // MARK: - SLOW STOP

    private func slowStopAnimation() {

        let startingAngle = fanAngle

        Task {

            var angle = startingAngle

            for _ in 0..<36 {

                if Task.isCancelled {
                    return
                }

                await MainActor.run {

                    angle += 10

                    if angle >= 360 {

                        angle -= 360
                    }

                    fanAngle = angle
                }

                try? await Task.sleep(
                    nanoseconds: 50_000_000
                )
            }

            await MainActor.run {

                selectedSpeed = 0
            }
        }
    }

    // MARK: - IMMEDIATE STOP

    private func stopFanImmediately() {

        animationTask?.cancel()

        fanSound?.stop()
        buttonSound?.stop()
        offSound?.stop()
    }

    // MARK: - BUTTON SOUND

    private func playButtonSound() {

        guard let url = Bundle.main.url(
            forResource: "fan_button_sound",
            withExtension: "mp3"
        ) else {
            return
        }

        do {

            buttonSound = try AVAudioPlayer(
                contentsOf: url
            )

            buttonSound?.prepareToPlay()
            buttonSound?.play()

        } catch {

            print(error)
        }
    }

    // MARK: - FAN RUNNING SOUND

    private func playFanSound() {

        guard let url = Bundle.main.url(
            forResource: "fan_on_sound",
            withExtension: "mp3"
        ) else {
            return
        }

        do {

            fanSound?.stop()

            fanSound = try AVAudioPlayer(
                contentsOf: url
            )

            fanSound?.numberOfLoops = -1

            fanSound?.prepareToPlay()
            fanSound?.play()

        } catch {

            print(error)
        }
    }

    // MARK: - FAN OFF SOUND

    private func playOffFanSound() {

        guard let url = Bundle.main.url(
            forResource: "fan_off_sound",
            withExtension: "mp3"
        ) else {
            return
        }

        do {

            offSound = try AVAudioPlayer(
                contentsOf: url
            )

            offSound?.prepareToPlay()
            offSound?.play()

        } catch {

            print(error)
        }
    }
}
