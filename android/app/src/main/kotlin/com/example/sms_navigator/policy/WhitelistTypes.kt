package com.example.sms_navigator.policy

enum class WhitelistMode {
    /** Chỉ sender khớp entry trong danh sách mới được relay. Danh sách trống = chặn tất cả. */
    EXPLICIT,

    /** SMS thường từ mọi đầu số được relay; OTP bắt buộc phải có entry khớp với allowOtp = true. */
    ALL_ADDRESSES
}

data class WhitelistEntry(
    val address: String,
    val allowOtp: Boolean = false
)

sealed class RelayDecision {
    object Allow : RelayDecision()
    data class Drop(val reason: String) : RelayDecision()
}
