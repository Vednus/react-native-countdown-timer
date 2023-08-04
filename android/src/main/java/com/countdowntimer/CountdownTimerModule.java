package com.countdowntimer;

import androidx.annotation.NonNull;

import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.module.annotations.ReactModule;

@ReactModule(name = CountdownTimerModule.NAME)
public class CountdownTimerModule extends ReactContextBaseJavaModule {
  public static final String NAME = "CountdownTimer";
  private Handler handler;
  private Runnable runnable;
  private MediaPlayer soundPlayer;    
  private Uri soundFileURI;

  public CountdownTimerModule(ReactApplicationContext reactContext) {
    super(reactContext);
  }

  @Override
  @NonNull
  public String getName() {
    return NAME;
  }


  // Example method
  // See https://reactnative.dev/docs/native-modules-android
  @ReactMethod
  public void multiply(double a, double b, Promise promise) {
    promise.resolve(a * b);
  }

  private Uri getAssetURI(String fileName) {
      AssetManager assetManager = getReactApplicationContext().getAssets();
      try {
          InputStream inputStream = assetManager.open("assets/" + fileName);
          File file = new File(getReactApplicationContext().getFilesDir(), fileName);
          OutputStream outputStream = new FileOutputStream(file);
          byte[] buffer = new byte[1024];
          int length;
          while ((length = inputStream.read(buffer)) > 0) {
              outputStream.write(buffer, 0, length);
          }
          outputStream.close();
          inputStream.close();
          return Uri.fromFile(file);
      } catch (IOException e) {
          e.printStackTrace();
      }
      return null;
  }

  @ReactMethod
  public void setSoundFileURI(String uriString) {
      if (uriString != null && !uriString.isEmpty()) {
          soundFileURI = Uri.parse(uriString);
      } else {
          // Use the default sound file if the provided URI is invalid
          String defaultSoundFileName = "bell.mp3";
          soundFileURI = getAssetURI(defaultSoundFileName);
      }
  }

    @ReactMethod
    public void startTimer(final double seconds, final Callback callback) {
        final long totalMilliseconds = (long) (seconds * 1000);
        new CountDownTimer(totalMilliseconds, 1000) {
            public void onTick(long millisUntilFinished) {
                long remainingSeconds = millisUntilFinished / 1000;
                callback.invoke(null, (double) remainingSeconds);
            }

            public void onFinish() {
                stopTimer();
                playSoundInBackground();
                callback.invoke(null, (double) 0); // Callback to the JavaScript with 0 to indicate the timer reached zero.
            }
        }.start();
    }

    @ReactMethod
    public void stopTimer() {
        if (runnable != null) {
            handler.removeCallbacks(runnable);
            runnable = null;
        }
    }

    @ReactMethod
    public void pauseTimer() {
        if (runnable != null) {
            handler.removeCallbacks(runnable);
        }
    }

    @ReactMethod
    public void resumeTimer() {
        if (runnable != null) {
            handler.postDelayed(runnable, 1000);
        }
    }

    private void playSoundInBackground() {
        if (soundPlayer == null) {
            soundPlayer = new MediaPlayer();
            try {
                soundPlayer.setDataSource(getReactApplicationContext(), soundFileURI);
                soundPlayer.prepare();
            } catch (Exception e) {
                e.printStackTrace();
            }
        }

        soundPlayer.setOnCompletionListener(new MediaPlayer.OnCompletionListener() {
            @Override
            public void onCompletion(MediaPlayer mp) {
                mp.seekTo(0);
            }
        });

        soundPlayer.start();
    }
}
