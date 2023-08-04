import { NativeModules, Platform } from 'react-native';
import * as FileSystem from 'expo-file-system';
import { Asset } from 'expo-asset';

const LINKING_ERROR =
  `The package 'react-native-countdown-timer' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo Go\n';

const CountdownTimer = NativeModules.CountdownTimer
  ? NativeModules.CountdownTimer
  : new Proxy(
      {},
      {
        get() {
          throw new Error(LINKING_ERROR);
        },
      }
    );

export function multiply(a: number, b: number): Promise<number> {
  return CountdownTimer.multiply(a, b);
}

export function startTimer(
  seconds: number,
  callback: (seconds: number) => void
): Promise<number> {
  return CountdownTimer.startTimer(seconds, callback);
}

export function stopTimer(): Promise<number> {
  return CountdownTimer.stopTimer();
}

export function pauseTimer(): Promise<number> {
  return CountdownTimer.pauseTimer();
}

export function resumeTimer(): Promise<number> {
  return CountdownTimer.resumeTimer();
}

export function setSoundFileURI(uriString: string): Promise<number> {
  return CountdownTimer.setSoundFileURI(uriString);
}

const setDefaultSoundFile = async () => {
  if (Platform.OS === 'android') {
    // @ts-ignore
    const defaultSoundFile = require('./assets/bell.mp3');
    const localUri = Asset.fromModule(defaultSoundFile).uri;
    CountdownTimer.setSoundFileURI(localUri);
  } else {
    // On iOS, copy the sound file to the app's document directory
    const soundFileName = 'bell.mp3';
    const soundFilePath = `${FileSystem.documentDirectory}${soundFileName}`;

    try {
      const { exists } = await FileSystem.getInfoAsync(soundFilePath);
      if (!exists) {
        await FileSystem.copyAsync({
          // @ts-ignore
          from: Asset.fromModule(require('./assets/bell.mp3')).uri,
          to: soundFilePath,
        });
      }

      CountdownTimer.setSoundFileURI(soundFilePath);
    } catch (error) {
      // @ts-ignore
      console.error('Error copying sound file:', error);
    }
  }
};

setDefaultSoundFile();
