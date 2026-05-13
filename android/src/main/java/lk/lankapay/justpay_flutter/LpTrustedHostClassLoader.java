package lk.lankapay.justpay_flutter;

import android.content.Context;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.io.InputStream;

/**
 * Delegates {@link ClassLoader#getResourceAsStream(String)} for LankaPay LPTrusted JSON paths to the
 * host app's {@link android.content.res.Resources} ({@code openRawResource}).
 *
 * <p>LPTrusted {@code ConfigManager.readJPJson} / {@code readMNVJson} load {@code justpay.json} and
 * {@code mnv.json} via {@code context.getClassLoader().getResourceAsStream("res/raw/…")}. That
 * classpath lookup does not reliably see Android {@code res/raw} assets in release APKs, while
 * {@link Context#getResources()} does. Routing those paths here avoids duplicating JSON as Java
 * resources (which breaks APK packaging with duplicate {@code res/raw/*} entries).</p>
 */
final class LpTrustedHostClassLoader extends ClassLoader {

    @NonNull
    private final Context resourceContext;

    LpTrustedHostClassLoader(@Nullable ClassLoader parent, @NonNull Context resourceContext) {
        super(parent != null ? parent : ClassLoader.getSystemClassLoader());
        this.resourceContext = resourceContext.getApplicationContext();
    }

    @Override
    public InputStream getResourceAsStream(@Nullable String name) {
        if (name == null) {
            return super.getResourceAsStream(null);
        }
        String normalized = name.startsWith("/") ? name.substring(1) : name;
        String rawBase = routedRawBasename(normalized);
        if (rawBase != null) {
            InputStream fromResources = openRawJson(rawBase);
            if (fromResources != null) {
                return fromResources;
            }
        }
        return super.getResourceAsStream(name);
    }

    /** LPTrusted hard-coded paths (see ConfigManager in LPTrustedSDK.aar). */
    @Nullable
    private static String routedRawBasename(@NonNull String normalizedPath) {
        if ("res/raw/justpay.json".equals(normalizedPath)) {
            return "justpay";
        }
        if ("res/raw/mnv.json".equals(normalizedPath)) {
            return "mnv";
        }
        return null;
    }

    @Nullable
    private InputStream openRawJson(@NonNull String rawBasename) {
        try {
            int resId =
                    resourceContext
                            .getResources()
                            .getIdentifier(rawBasename, "raw", resourceContext.getPackageName());
            if (resId == 0) {
                return null;
            }
            return resourceContext.getResources().openRawResource(resId);
        } catch (Throwable ignored) {
            return null;
        }
    }
}
