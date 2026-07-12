package com.hey.mery.wake_word;

import android.content.Context;
import android.util.Log;

import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;

public class WakeWordEngine {
    private static final String TAG = "WakeWordEngine";
    private static final int SAMPLE_RATE = 16000;
    private static final float ENERGY_THRESHOLD = 0.02f;
    private static final float PEAK_THRESHOLD = 0.15f;
    private static final int MIN_DETECTION_FRAMES = 8;
    private static final int MAX_DETECTION_FRAMES = 60;
    private static final long COOLDOWN_MS = 3000;

    private boolean initialized = false;
    private float[] audioBuffer;
    private int bufferIndex = 0;
    private static final int BUFFER_SIZE = SAMPLE_RATE * 2;

    private int sustainedFrames = 0;
    private float peakAmplitude = 0f;
    private long lastDetectionTime = 0;

    private OnWakeWordListener listener;

    public interface OnWakeWordListener {
        void onWakeWordDetected(float confidence);
    }

    public WakeWordEngine() {
        audioBuffer = new float[BUFFER_SIZE];
    }

    public boolean initialize(Context context) {
        try {
            String modelPath = copyModelToCache(context, "models/hey_jarvis.onnx");
            if (modelPath == null) {
                Log.w(TAG, "Model file not found, using audio energy detection");
            }

            initialized = true;
            Log.d(TAG, "WakeWordEngine initialized (energy-based detection)");
            return true;
        } catch (Exception e) {
            Log.e(TAG, "Initialization failed: " + e.getMessage());
            return false;
        }
    }

    private String copyModelToCache(Context context, String assetPath) {
        try {
            File cacheDir = new File(context.getCacheDir(), "models");
            if (!cacheDir.exists()) cacheDir.mkdirs();

            File modelFile = new File(cacheDir, "hey_jarvis.onnx");
            if (modelFile.exists()) return modelFile.getAbsolutePath();

            InputStream is = context.getAssets().open(assetPath);
            FileOutputStream fos = new FileOutputStream(modelFile);
            byte[] buffer = new byte[1024];
            int read;
            while ((read = is.read(buffer)) != -1) {
                fos.write(buffer, 0, read);
            }
            fos.close();
            is.close();

            return modelFile.getAbsolutePath();
        } catch (Exception e) {
            Log.d(TAG, "Model not available in assets: " + e.getMessage());
            return null;
        }
    }

    public float processAudio(short[] audioData) {
        if (!initialized) return 0f;

        float frameMax = 0f;
        float frameEnergy = 0f;

        for (short sample : audioData) {
            float normalized = sample / 32768.0f;
            float absVal = Math.abs(normalized);
            audioBuffer[bufferIndex] = normalized;
            bufferIndex = (bufferIndex + 1) % BUFFER_SIZE;

            if (absVal > frameMax) {
                frameMax = absVal;
            }
            frameEnergy += absVal;
        }

        frameEnergy /= audioData.length;

        if (frameMax > peakAmplitude) {
            peakAmplitude = frameMax;
        }

        if (frameEnergy > ENERGY_THRESHOLD) {
            sustainedFrames++;

            if (sustainedFrames >= MIN_DETECTION_FRAMES &&
                sustainedFrames <= MAX_DETECTION_FRAMES &&
                peakAmplitude > PEAK_THRESHOLD) {

                long now = System.currentTimeMillis();
                if (now - lastDetectionTime > COOLDOWN_MS) {
                    float confidence = Math.min(1.0f,
                        (frameEnergy / ENERGY_THRESHOLD) * 0.5f +
                        (peakAmplitude / PEAK_THRESHOLD) * 0.5f
                    );

                    if (confidence > 0.8f) {
                        lastDetectionTime = now;
                        sustainedFrames = 0;
                        peakAmplitude = 0f;

                        if (listener != null) {
                            listener.onWakeWordDetected(confidence);
                        }
                        return confidence;
                    }
                }
            }
        } else {
            sustainedFrames = 0;
            peakAmplitude = 0f;
        }

        return 0f;
    }

    public void setOnWakeWordListener(OnWakeWordListener listener) {
        this.listener = listener;
    }

    public void release() {
        initialized = false;
        audioBuffer = null;
        listener = null;
    }

    public boolean isInitialized() {
        return initialized;
    }
}
