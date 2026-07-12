package com.hey.mery.wake_word;

import android.content.Context;
import android.util.Log;

import java.io.InputStream;
import java.nio.FloatBuffer;
import java.util.HashMap;
import java.util.Map;

import ai.onnxruntime.OnnxTensor;
import ai.onnxruntime.OrtEnvironment;
import ai.onnxruntime.OrtSession;

public class WakeWordEngine {
    private static final String TAG = "WakeWordEngine";

    private static final int CHUNK_SAMPLES = 1280;
    private static final int MEL_BINS = 32;
    private static final int MEL_WINDOW = 76;
    private static final int EMBEDDING_DIM = 96;
    private static final int EMBEDDING_WINDOW = 16;
    private static final int MEL_MAX_FRAMES = 970;
    private static final int EMBEDDING_MAX_FRAMES = 120;
    private static final float DETECTION_THRESHOLD = 0.5f;
    private static final long COOLDOWN_MS = 3000;

    private OrtEnvironment ortEnv;
    private OrtSession melSpecSession;
    private OrtSession embeddingSession;
    private OrtSession classifierSession;

    private String melSpecInputName;
    private String embeddingInputName;
    private String classifierInputName;

    private float[][] melBuffer = new float[MEL_MAX_FRAMES][MEL_BINS];
    private int melWriteIndex = 0;
    private int melCount = 0;

    private float[][] embeddingBuffer = new float[EMBEDDING_MAX_FRAMES][EMBEDDING_DIM];
    private int embeddingWriteIndex = 0;
    private int embeddingCount = 0;

    private long lastDetectionTime = 0;
    private boolean initialized = false;

    private OnWakeWordListener listener;

    public interface OnWakeWordListener {
        void onWakeWordDetected(float confidence);
    }

    public boolean initialize(Context context) {
        try {
            ortEnv = OrtEnvironment.getEnvironment();

            melSpecSession = loadModel(context, "models/melspectrogram.onnx");
            embeddingSession = loadModel(context, "models/embedding_model.onnx");
            classifierSession = loadModel(context, "models/hey_jarvis.onnx");

            melSpecInputName = melSpecSession.getInputNames().iterator().next();
            embeddingInputName = embeddingSession.getInputNames().iterator().next();
            classifierInputName = classifierSession.getInputNames().iterator().next();

            Log.d(TAG, "Models loaded. Input names: mel=" + melSpecInputName
                    + ", emb=" + embeddingInputName + ", clf=" + classifierInputName);

            initialized = true;
            return true;
        } catch (Exception e) {
            Log.e(TAG, "Initialization failed: " + e.getMessage(), e);
            return false;
        }
    }

    private OrtSession loadModel(Context context, String assetPath) throws Exception {
        InputStream is = context.getAssets().open(assetPath);
        byte[] modelBytes = new byte[is.available()];
        int offset = 0;
        while (offset < modelBytes.length) {
            int read = is.read(modelBytes, offset, modelBytes.length - offset);
            if (read == -1) break;
            offset += read;
        }
        is.close();
        return ortEnv.createSession(modelBytes);
    }

    public float processAudio(short[] audioData) {
        if (!initialized || audioData.length != CHUNK_SAMPLES) return 0f;

        float[] floatAudio = new float[CHUNK_SAMPLES];
        for (int i = 0; i < CHUNK_SAMPLES; i++) {
            floatAudio[i] = (float) audioData[i];
        }

        float[][] melFrames = runMelSpecModel(floatAudio);
        if (melFrames == null) return 0f;

        for (float[] frame : melFrames) {
            for (int j = 0; j < MEL_BINS; j++) {
                frame[j] = frame[j] / 10.0f + 2.0f;
            }
            melBuffer[melWriteIndex] = frame;
            melWriteIndex = (melWriteIndex + 1) % MEL_MAX_FRAMES;
            melCount = Math.min(melCount + 1, MEL_MAX_FRAMES);
        }

        if (melCount >= MEL_WINDOW) {
            float[] embedding = runEmbeddingModel();
            if (embedding != null) {
                embeddingBuffer[embeddingWriteIndex] = embedding;
                embeddingWriteIndex = (embeddingWriteIndex + 1) % EMBEDDING_MAX_FRAMES;
                embeddingCount = Math.min(embeddingCount + 1, EMBEDDING_MAX_FRAMES);
            }
        }

        if (embeddingCount >= EMBEDDING_WINDOW) {
            float score = runClassifierModel();
            if (score > DETECTION_THRESHOLD) {
                long now = System.currentTimeMillis();
                if (now - lastDetectionTime > COOLDOWN_MS) {
                    lastDetectionTime = now;
                    Log.d(TAG, "Wake word detected! Score: " + score);
                    if (listener != null) {
                        listener.onWakeWordDetected(score);
                    }
                    return score;
                }
            }
        }

        return 0f;
    }

    private float[][] runMelSpecModel(float[] audio) {
        try {
            long[] shape = {1, CHUNK_SAMPLES};
            OnnxTensor inputTensor = OnnxTensor.createTensor(ortEnv,
                    FloatBuffer.wrap(audio), shape);
            Map<String, OnnxTensor> inputs = new HashMap<>();
            inputs.put(melSpecInputName, inputTensor);

            OrtSession.Result result = melSpecSession.run(inputs);
            float[][][][] output = (float[][][][]) result.get(0).getValue();
            inputTensor.close();
            result.close();

            return output[0][0];
        } catch (Exception e) {
            Log.e(TAG, "MelSpec error: " + e.getMessage());
            return null;
        }
    }

    private float[] runEmbeddingModel() {
        try {
            float[][][] window = new float[MEL_WINDOW][MEL_BINS][1];
            int startIdx = (melWriteIndex - MEL_WINDOW + MEL_MAX_FRAMES) % MEL_MAX_FRAMES;
            for (int i = 0; i < MEL_WINDOW; i++) {
                int idx = (startIdx + i) % MEL_MAX_FRAMES;
                for (int j = 0; j < MEL_BINS; j++) {
                    window[i][j][0] = melBuffer[idx][j];
                }
            }

            long[] shape = {1, MEL_WINDOW, MEL_BINS, 1};
            float[] flat = new float[MEL_WINDOW * MEL_BINS];
            int k = 0;
            for (int i = 0; i < MEL_WINDOW; i++) {
                for (int j = 0; j < MEL_BINS; j++) {
                    flat[k++] = window[i][j][0];
                }
            }

            OnnxTensor inputTensor = OnnxTensor.createTensor(ortEnv,
                    FloatBuffer.wrap(flat), shape);
            Map<String, OnnxTensor> inputs = new HashMap<>();
            inputs.put(embeddingInputName, inputTensor);

            OrtSession.Result result = embeddingSession.run(inputs);
            Object rawOutput = result.get(0).getValue();
            float[] embedding;
            if (rawOutput instanceof float[][][]) {
                embedding = ((float[][][]) rawOutput)[0][0];
            } else if (rawOutput instanceof float[][]) {
                embedding = ((float[][]) rawOutput)[0];
            } else {
                embedding = (float[]) rawOutput;
            }

            inputTensor.close();
            result.close();
            return embedding;
        } catch (Exception e) {
            Log.e(TAG, "Embedding error: " + e.getMessage());
            return null;
        }
    }

    private float runClassifierModel() {
        try {
            float[] flat = new float[EMBEDDING_WINDOW * EMBEDDING_DIM];
            int startIdx = (embeddingWriteIndex - EMBEDDING_WINDOW + EMBEDDING_MAX_FRAMES) % EMBEDDING_MAX_FRAMES;
            int k = 0;
            for (int i = 0; i < EMBEDDING_WINDOW; i++) {
                int idx = (startIdx + i) % EMBEDDING_MAX_FRAMES;
                for (int j = 0; j < EMBEDDING_DIM; j++) {
                    flat[k++] = embeddingBuffer[idx][j];
                }
            }

            long[] shape = {1, EMBEDDING_WINDOW, EMBEDDING_DIM};
            OnnxTensor inputTensor = OnnxTensor.createTensor(ortEnv,
                    FloatBuffer.wrap(flat), shape);
            Map<String, OnnxTensor> inputs = new HashMap<>();
            inputs.put(classifierInputName, inputTensor);

            OrtSession.Result result = classifierSession.run(inputs);
            Object rawOutput = result.get(0).getValue();
            float score;
            if (rawOutput instanceof float[][]) {
                score = ((float[][]) rawOutput)[0][0];
            } else if (rawOutput instanceof float[]) {
                score = ((float[]) rawOutput)[0];
            } else {
                score = (float) rawOutput;
            }

            inputTensor.close();
            result.close();
            return score;
        } catch (Exception e) {
            Log.e(TAG, "Classifier error: " + e.getMessage());
            return 0f;
        }
    }

    public void setOnWakeWordListener(OnWakeWordListener listener) {
        this.listener = listener;
    }

    public void release() {
        initialized = false;
        try {
            if (melSpecSession != null) melSpecSession.close();
            if (embeddingSession != null) embeddingSession.close();
            if (classifierSession != null) classifierSession.close();
            if (ortEnv != null) ortEnv.close();
        } catch (Exception e) {
            Log.e(TAG, "Error releasing: " + e.getMessage());
        }
        listener = null;
    }

    public boolean isInitialized() {
        return initialized;
    }
}
