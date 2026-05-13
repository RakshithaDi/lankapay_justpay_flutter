package lk.lankapay.justpay_flutter;

import android.content.Context;
import android.content.ContextWrapper;

import androidx.annotation.NonNull;

/**
 * Context wrapper used only when calling {@link com.lankapay.justpay.LPTrustedSDKManager#getInstance(Context)}.
 *
 * <p>{@link LPTrustedSDKManager#getInstance(Context)} passes {@link Context#getApplicationContext()}
 * into native init. The stock implementation returns the real {@link android.app.Application}, whose
 * {@link ClassLoader} cannot resolve {@code res/raw/justpay.json} for LPTrusted. We override
 * {@link #getApplicationContext()} to return {@code this} so init keeps using {@link LpTrustedHostClassLoader},
 * while {@link #getResources()}, {@link #getPackageName()}, etc. still delegate to the real app context.</p>
 */
final class LpTrustedApplicationContext extends ContextWrapper {

    @NonNull
    private final ClassLoader lpTrustedClassLoader;

    LpTrustedApplicationContext(@NonNull Context realApplicationContext) {
        super(realApplicationContext);
        lpTrustedClassLoader =
                new LpTrustedHostClassLoader(realApplicationContext.getClassLoader(), realApplicationContext);
    }

    @NonNull
    @Override
    public Context getApplicationContext() {
        return this;
    }

    @NonNull
    @Override
    public ClassLoader getClassLoader() {
        return lpTrustedClassLoader;
    }
}
