package kr.sjh.runlini.wear

import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.asSharedFlow

object WearGhostConfigChangeBus {
    private val _changes = MutableSharedFlow<Unit>(extraBufferCapacity = 1)
    val changes: SharedFlow<Unit> = _changes.asSharedFlow()

    fun notifyChanged() {
        _changes.tryEmit(Unit)
    }
}
