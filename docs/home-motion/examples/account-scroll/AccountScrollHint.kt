package examples.accountscroll

import androidx.compose.animation.core.AnimationState
import androidx.compose.animation.core.CubicBezierEasing
import androidx.compose.animation.core.animateTo
import androidx.compose.animation.core.tween
import androidx.compose.foundation.MutatePriority
import androidx.compose.foundation.ScrollState
import androidx.compose.foundation.gestures.ScrollScope
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.rememberScrollState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.input.key.onPreviewKeyEvent
import androidx.compose.ui.input.pointer.PointerEventPass
import androidx.compose.ui.input.pointer.PointerEventType
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.delay

@Composable
fun AccountCarouselExample(
    loadingFinished: Boolean,
    reduceMotion: Boolean,
    modifier: Modifier = Modifier,
    scroll: ScrollState = rememberScrollState(),
    cards: @Composable RowScope.() -> Unit,
) {
    var consumed by rememberSaveable { mutableStateOf(false) }
    var interactionStarted by rememberSaveable { mutableStateOf(false) }
    val density = LocalDensity.current
    val maxDistance = with(density) { 36.dp.toPx() }
    val minDistance = with(density) { 4.dp.toPx() }

    LaunchedEffect(loadingFinished, reduceMotion, interactionStarted, scroll) {
        if (!loadingFinished || consumed || interactionStarted) return@LaunchedEffect
        consumed = true
        if (reduceMotion) return@LaunchedEffect

        delay(1_000)
        if (scroll.isScrollInProgress || scroll.value != 0 || scroll.maxValue == Int.MAX_VALUE) return@LaunchedEffect

        scroll.scroll(MutatePriority.Default) {
            val origin = scroll.value
            val distance = minOf(maxDistance, (scroll.maxValue - origin).toFloat())
            if (distance < minDistance) return@scroll

            moveBy(distance, 378, CubicBezierEasing(0.22f, 1f, 0.36f, 1f))
            moveBy(-distance, 522, CubicBezierEasing(0.45f, 0f, 0.25f, 1f))
            scrollBy((origin - scroll.value).toFloat())
        }
    }

    Row(
        modifier
            .onPreviewKeyEvent {
                interactionStarted = true
                false
            }
            .pointerInput(Unit) {
                awaitPointerEventScope {
                    while (true) {
                        val event = awaitPointerEvent(PointerEventPass.Initial)
                        if (event.type == PointerEventType.Scroll ||
                            event.changes.any { it.pressed && !it.previousPressed }
                        ) interactionStarted = true
                    }
                }
            }
            .horizontalScroll(scroll),
        content = cards,
    )
}

private suspend fun ScrollScope.moveBy(distance: Float, millis: Int, easing: CubicBezierEasing) {
    var previous = 0f
    AnimationState(initialValue = 0f).animateTo(distance, tween(millis, easing = easing)) {
        scrollBy(value - previous)
        previous = value
    }
}
