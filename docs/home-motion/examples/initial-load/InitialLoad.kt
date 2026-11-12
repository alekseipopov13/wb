package examples.initialload

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.CubicBezierEasing
import androidx.compose.animation.core.tween
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.Stable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.PointerEventPass
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.withContext

// Example names are arbitrary. Retain this state with the screen owner above
// navigation destinations; a new instance denotes a new opening of the screen.
@Stable
class InitialLoadMotion {
    val skeletonOpacity = Animatable(1f)
    var showsSkeleton by mutableStateOf(true)
        private set
    var isWaiting by mutableStateOf(true)
        private set
    var isFinished by mutableStateOf(false)
        private set
    private var started = false

    // Invoke on the UI dispatcher with a Compose frame clock. The application
    // supplies readiness; this example never waits for a loading timeout.
    suspend fun contentBecameReady(reduceMotion: Boolean) {
        if (started) return
        started = true
        isWaiting = false
        try {
            if (!reduceMotion) {
                skeletonOpacity.animateTo(
                    0f, tween(220, easing = CubicBezierEasing(0f, 0f, 0.58f, 1f))
                )
            }
        } finally {
            // An interrupted owner completes without replaying from skeletons.
            // Do not cancel this owner merely because a detail screen is pushed.
            withContext(NonCancellable) {
                skeletonOpacity.snapTo(0f)
                showsSkeleton = false
                isWaiting = false
                isFinished = true
            }
        }
    }
}

// Wrap all home content. Use isWaiting to disable actions in your controls and
// report a localized loading state through your accessibility layer.
// skeleton supplies the design-system shimmer, or static shapes in reduced motion.
@Composable
fun InitialLoadExample(
    motion: InitialLoadMotion,
    contentReady: Boolean,
    reduceMotion: Boolean,
    modifier: Modifier = Modifier,
    content: @Composable BoxScope.(InitialLoadMotion) -> Unit,
    skeleton: @Composable BoxScope.() -> Unit,
) {
    LaunchedEffect(contentReady, reduceMotion) {
        if (contentReady) motion.contentBecameReady(reduceMotion)
    }
    Box(modifier, contentAlignment = Alignment.TopStart) {
        Box(
            if (motion.isWaiting) Modifier.clearAndSetSemantics {}.pointerInput(Unit) {
                awaitPointerEventScope {
                    while (true) {
                        awaitPointerEvent(PointerEventPass.Initial).changes.forEach { it.consume() }
                    }
                }
            } else Modifier,
        ) { content(motion) }
        if (motion.showsSkeleton) {
            Box(
                Modifier.graphicsLayer { alpha = motion.skeletonOpacity.value }
                    .clearAndSetSemantics {},
                content = skeleton,
            )
        }
    }
}

// Static right-hand cards. The supplied skeleton view covers the ENTIRE
// benefits area with ONE rounded placeholder: height 116 dp, radius 20 dp.
@Composable
fun BenefitsLayoutExample(
    cashback: @Composable BoxScope.() -> Unit,
    referral: @Composable BoxScope.() -> Unit,
    modifier: Modifier = Modifier,
) {
    Box(modifier.size(119.dp, 126.dp), contentAlignment = Alignment.TopCenter) {
        Box(Modifier.size(119.dp, 68.dp).clipToBounds(), content = cashback)
        Box(
            Modifier.offset(y = 67.6.dp).size(115.dp, 51.dp)
                .graphicsLayer { rotationZ = -10f },
            content = referral,
        )
    }
}
