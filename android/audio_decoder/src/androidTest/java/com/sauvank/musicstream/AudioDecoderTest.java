package com.sauvank.musicstream;

import static org.junit.Assert.*;

import android.content.Context;
import android.os.Handler;
import android.os.Looper;
import androidx.media3.common.MediaItem;
import androidx.media3.common.PlaybackException;
import androidx.media3.common.Player;
import androidx.media3.decoder.ffmpeg.FfmpegLibrary;
import androidx.media3.exoplayer.DefaultRenderersFactory;
import androidx.media3.exoplayer.ExoPlayer;
import androidx.media3.exoplayer.analytics.AnalyticsListener;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import androidx.test.platform.app.InstrumentationRegistry;
import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicReference;
import org.junit.Test;
import org.junit.runner.RunWith;

/** Real demuxing, decoding and AudioTrack output, not a mocked player. */
@RunWith(AndroidJUnit4.class)
public class AudioDecoderTest {
    @Test public void bundledCodecsAreAvailable() {
        assertTrue(FfmpegLibrary.isAvailable());
        assertTrue(FfmpegLibrary.supportsFormat("audio/mp4a-latm"));
        assertTrue(FfmpegLibrary.supportsFormat("audio/alac"));
        assertTrue(FfmpegLibrary.supportsFormat("audio/flac"));
    }

    @Test public void aacM4aStillPlays() throws Exception {
        play("aac.m4a", false);
    }

    @Test public void alacM4aPlaysThroughSoftwareDecoder() throws Exception {
        play("alac.m4a", true);
    }

    private void play(String asset, boolean requireSoftware) throws Exception {
        Context tests = InstrumentationRegistry.getInstrumentation().getContext();
        Context app = InstrumentationRegistry.getInstrumentation().getTargetContext();
        File input = new File(app.getCacheDir(), asset);
        try (InputStream in = tests.getAssets().open(asset);
             FileOutputStream out = new FileOutputStream(input)) {
            byte[] buffer = new byte[8192];
            int count;
            while ((count = in.read(buffer)) != -1) out.write(buffer, 0, count);
        }
        Handler handler = new Handler(Looper.getMainLooper());
        CountDownLatch ended = new CountDownLatch(1);
        CountDownLatch released = new CountDownLatch(1);
        AtomicReference<ExoPlayer> player = new AtomicReference<>();
        AtomicReference<String> error = new AtomicReference<>();
        AtomicReference<String> decoder = new AtomicReference<>("");
        AtomicBoolean advancing = new AtomicBoolean(false);
        handler.post(() -> {
            ExoPlayer audio = new ExoPlayer.Builder(app,
                new DefaultRenderersFactory(app)
                    .setExtensionRendererMode(DefaultRenderersFactory.EXTENSION_RENDERER_MODE_ON)
                    .setEnableDecoderFallback(true)).build();
            player.set(audio);
            audio.addAnalyticsListener(new AnalyticsListener() {
                @Override public void onAudioDecoderInitialized(EventTime time, String name,
                        long timestamp, long duration) { decoder.set(name); }
                @Override public void onAudioPositionAdvancing(EventTime time, long start) {
                    advancing.set(true);
                }
            });
            audio.addListener(new Player.Listener() {
                @Override public void onPlaybackStateChanged(int state) {
                    if (state == Player.STATE_ENDED) ended.countDown();
                }
                @Override public void onPlayerError(PlaybackException failure) {
                    error.set(failure.toString());
                    ended.countDown();
                }
            });
            audio.setMediaItem(MediaItem.fromUri(input.toURI().toString()));
            audio.prepare();
            audio.play();
        });
        boolean completed;
        try {
            completed = ended.await(45, TimeUnit.SECONDS);
        } finally {
            handler.post(() -> {
                if (player.get() != null) player.get().release();
                released.countDown();
            });
            assertTrue("Player release timed out", released.await(10, TimeUnit.SECONDS));
            input.delete();
        }
        assertTrue("Playback timed out", completed);
        assertNull(error.get(), error.get());
        assertTrue("No audio reached AudioTrack", advancing.get());
        if (requireSoftware) assertTrue(decoder.get(), decoder.get().startsWith("ffmpeg"));
    }
}
