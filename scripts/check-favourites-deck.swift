import Foundation

@main
enum CheckFavouritesDeck {
    static func main() {
        var gesture = FavouritesDeckInteraction()
        func check(_ value: @autoclosure () -> Bool, _ message: String) {
            precondition(value(), message)
        }
        // Прокрутка к краю и инерционный отскок не должны открыть другой экран.
        _ = gesture.update(distance: 120, isInteracting: false, hasOverflow: true)
        check(!gesture.shouldOpenOnRelease, "Инерция не активирует переход")
        _ = gesture.update(distance: 100, isInteracting: true, hasOverflow: false)
        check(!gesture.shouldOpenOnRelease && gesture.progress == 0, "Без скрытых избранных нет стопки и перехода")
        _ = gesture.update(distance: -20, isInteracting: true, hasOverflow: true)
        check(gesture.progress == 0, "Левый край не раскрывает избранное")
        _ = gesture.update(distance: 50, isInteracting: true, hasOverflow: true)
        check(gesture.progress > 0 && !gesture.shouldOpenOnRelease, "Короткое протягивание можно отменить")
        check(gesture.update(distance: 75, isInteracting: true, hasOverflow: true) == .ready, "Порог даёт сигнал готовности")
        check(gesture.shouldOpenOnRelease, "Протягивание за порог открывает избранное при отпускании")
        check(gesture.update(distance: 80, isInteracting: true, hasOverflow: true) == .none, "Нет повторного хаптика на каждом кадре")
        _ = gesture.update(distance: 60, isInteracting: true, hasOverflow: true)
        check(gesture.shouldOpenOnRelease, "Гистерезис защищает от дрожания около порога")
        check(gesture.update(distance: 40, isInteracting: true, hasOverflow: true) == .disarmed, "Возврат пальца отменяет готовность")
        check(!gesture.shouldOpenOnRelease, "После отмены экран не открывается")
        gesture.reset()
        check(gesture.progress == 0 && !gesture.isArmed, "Следующий жест начинается с нуля")
        print("Favourites deck: inertia, cancellation, hysteresis and haptic gating passed")
    }
}
