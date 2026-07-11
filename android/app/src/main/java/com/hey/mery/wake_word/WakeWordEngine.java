package com.hey.mery.wake_word;

import android.content.Context;
import android.content.res.AssetManager;
import android.util.Log;

import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.FloatBuffer;

public class WakeWordEngine {
    private static final String TAG = "WakeWordEngine";
    private static final int SAMPLE_RATE = 16000;
    private static final float THRESHOLD = 0.5f;

    private boolean initialized = false;
    private float[] audioBuffer;
    private int bufferIndex = 0;
    private static final int BUFFER_SIZE = SAMPLE_RATE * 2;

    private OnWakeWordListener listener;

    public interface OnWakeWordListener {
        void onWakeWordDetected(float confidence);
    }

    public WakeWordEngine() {
        audioBuffer = new float[BUFFER_SIZE];
    }

    public boolean initialize(Context context) {
        try {
            AssetManager am = context.getAssets();
            String modelPath = copyModelToCache(context, "models/hey_jarvis.onnx");
            if (modelPath == null) {
                Log.e(TAG, "Failed to copy model file");
                return false;
            }

            // TODO: Initialize ONNX Runtime with model
            // For now, using a simplified audio energy detection as placeholder
            initialized = true;
            Log.d(TAG, "WakeWordEngine initialized");
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
            Log.e(TAG, "Error copying model: " + e.getMessage());
            return null;
        }
    }

    public float processAudio(short[] audioData) {
        if (!initialized) return 0f;

        for (short sample : audioData) {
            float normalized = sample / 32768.0f;
            audioBuffer[bufferIndex] = normalized;
            bufferIndex = (bufferIndex + 1) % BUFFER_SIZE;

            if (bufferIndex == 0) {
                float energy = calculateEnergy();
                if (energy > THRESHOLD) {
                    if (listener != null) {
                        listener.onWakeWordDetected(energy);
                    }
                    return energy;
                }
            }
        }
        return 0f;
    }

    private float calculateEnergy() {
        float sum = 0;
        for (float sample : audioBuffer) {
            sum += Math.abs(sample);
        }
        return sum / BUFFER_SIZE;
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
