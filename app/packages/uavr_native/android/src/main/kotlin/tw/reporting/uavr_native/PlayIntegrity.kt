package tw.reporting.uavr_native

import android.content.Context
import android.util.Log
import com.google.android.play.core.integrity.IntegrityManagerFactory
import com.google.android.play.core.integrity.StandardIntegrityManager
import com.google.android.play.core.integrity.StandardIntegrityManager.PrepareIntegrityTokenRequest
import com.google.android.play.core.integrity.StandardIntegrityManager.StandardIntegrityTokenProvider
import com.google.android.play.core.integrity.StandardIntegrityManager.StandardIntegrityTokenRequest

/**
 * Play Integrity standard requests. The token provider is prepared once per
 * cloud project and cached; if a request with a cached provider fails (e.g.
 * the provider expired) it is re-prepared once. Any failure yields null.
 */
internal class PlayIntegrity(context: Context) {
    private val context = context.applicationContext
    private var manager: StandardIntegrityManager? = null
    private val providers = HashMap<Long, StandardIntegrityTokenProvider>()

    fun token(requestHash: String, cloudProjectNumber: Long, done: (String?) -> Unit) {
        val mgr = try {
            manager ?: IntegrityManagerFactory.createStandard(context).also { manager = it }
        } catch (e: Exception) {
            Log.w(TAG, "Play Integrity unavailable", e)
            return done(null)
        }
        val cached = providers[cloudProjectNumber]
        if (cached != null) {
            request(mgr, cached, requestHash, cloudProjectNumber, retry = true, done)
        } else {
            prepare(mgr, requestHash, cloudProjectNumber, done)
        }
    }

    private fun prepare(mgr: StandardIntegrityManager, hash: String, project: Long, done: (String?) -> Unit) {
        val req = PrepareIntegrityTokenRequest.builder().setCloudProjectNumber(project).build()
        mgr.prepareIntegrityToken(req)
            .addOnSuccessListener { provider ->
                providers[project] = provider
                request(mgr, provider, hash, project, retry = false, done)
            }
            .addOnFailureListener {
                Log.w(TAG, "prepareIntegrityToken failed", it)
                done(null)
            }
    }

    private fun request(
        mgr: StandardIntegrityManager,
        provider: StandardIntegrityTokenProvider,
        hash: String,
        project: Long,
        retry: Boolean,
        done: (String?) -> Unit,
    ) {
        provider.request(StandardIntegrityTokenRequest.builder().setRequestHash(hash).build())
            .addOnSuccessListener { done(it.token()) }
            .addOnFailureListener {
                providers.remove(project)
                if (retry) {
                    prepare(mgr, hash, project, done)
                } else {
                    Log.w(TAG, "Integrity token request failed", it)
                    done(null)
                }
            }
    }

    private companion object {
        const val TAG = "UavrIntegrity"
    }
}
