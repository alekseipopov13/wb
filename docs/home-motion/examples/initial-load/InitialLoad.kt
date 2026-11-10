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
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

// Example names are arbitrary. Retain this state with the screen owner above
// navigation destinations; a new instance denotes a new opening of the screen.
@Stable
class InitialLoadMotion {
    val cashbackHeight = Animatable(116f)
    val referralProgress = Animatable(0f)
    val referralAngle = Animatable(0f)
    val skeletonOpacity = Animatable(1f)
    var showsSkeleton by mutableStateOf(true)
        private set
    var allowsReferral by mutableStateOf(false)
        private set
    var isWaiting by mutableStateOf(true)
        private set
    var isFinished by mutableStateOf(false)
        private set
    private var started = false
    private val curve = CubicBezierEasing(0.22f, 1f, 0.36f, 1f)

    // Invoke on the UI dispatcher with a Compose frame clock. The application
    // supplies readiness; this example never waits for a loading timeout.
    suspend fun contentBecameReady(reduceMotion: Boolean) {
        if (started) return
        started = true
        isWaiting = false
        try {
            if (!reduceMotion) {
                coroutineScope {
                    launch {
                        skeletonOpacity.animateTo(
                            0f, tween(220, easing = CubicBezierEasing(0f, 0f, 0.58f, 1f))
                        )
                        showsSkeleton = false
                    }
                    // Measured from T; overlaps the fade instead of following it.
                    delay(300)
                    cashbackHeight.animateTo(68f, tween(400, easing = curve))
                    allowsReferral = true
                    referralProgress.animateTo(1f, tween(300, easing = curve))
                    referralAngle.animateTo(-10f, tween(280, easing = curve))
                }
            }
        } finally {
            // An interrupted owner completes without replaying from skeletons.
            // Do not cancel this owner merely because a detail screen is pushed.
            withContext(NonCancellable) {
                cashbackHeight.snapTo(68f)
                referralProgress.snapTo(1f)
                referralAngle.snapTo(-10f)
                skeletonOpacity.snapTo(0f)
                showsSkeleton = false
                allowsReferral = true
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

// Animated slot only. Supply your own card views. Pin the amount 12 dp from the
// bottom inside the cashback card; height changes, font size does not.
@Composable
fun BenefitsMotionExample(
    motion: InitialLoadMotion,
    cashback: @Composable BoxScope.() -> Unit,
    referral: @Composable BoxScope.() -> Unit,
    modifier: Modifier = Modifier,
) {
    Box(modifier.size(119.dp, 126.dp), contentAlignment = Alignment.TopCenter) {
        Box(
            Modifier.size(119.dp, motion.cashbackHeight.value.dp).clipToBounds(),
            content = cashback,
        )
        if (motion.allowsReferral) Box(
            Modifier.offset(y = 67.6.dp).size(115.dp, 51.dp)
                .graphicsLayer {
                    alpha = motion.referralProgress.value
                    scaleX = 0.9f + 0.1f * motion.referralProgress.value
                    scaleY = scaleX
                    rotationZ = motion.referralAngle.value
                },
            content = referral,
        )
    }
}
