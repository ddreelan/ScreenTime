package com.screentime.app.service

import android.content.Context
import android.content.SharedPreferences
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.security.MessageDigest
import java.security.SecureRandom

class AuthService(context: Context) {
    private val prefs: SharedPreferences =
        context.getSharedPreferences("screentime_auth", Context.MODE_PRIVATE)

    private val _authState = MutableStateFlow(isAuthenticated())
    val authState: StateFlow<Boolean> = _authState.asStateFlow()

    private val _currentUserEmail = MutableStateFlow(loadCurrentEmail())
    val currentUserEmail: StateFlow<String?> = _currentUserEmail.asStateFlow()

    suspend fun signIn(email: String, password: String): Boolean {
        val trimmedEmail = email.lowercase().trim()
        if (trimmedEmail.isEmpty() || password.isEmpty()) return false

        val storedHash = prefs.getString("hash.$trimmedEmail", null) ?: return false
        val storedSalt = prefs.getString("salt.$trimmedEmail", null) ?: return false

        val inputHash = hashPassword(password, storedSalt)
        if (inputHash != storedHash) return false

        prefs.edit()
            .putString("session_email", trimmedEmail)
            .apply()

        _authState.value = true
        _currentUserEmail.value = trimmedEmail
        return true
    }

    suspend fun register(email: String, password: String, name: String): Boolean {
        val trimmedEmail = email.lowercase().trim()
        if (trimmedEmail.isEmpty() || password.length < 8 || name.isEmpty()) return false

        if (prefs.getString("hash.$trimmedEmail", null) != null) return false

        val salt = generateSalt()
        val hashed = hashPassword(password, salt)

        prefs.edit()
            .putString("hash.$trimmedEmail", hashed)
            .putString("salt.$trimmedEmail", salt)
            .putString("name.$trimmedEmail", name)
            .putString("session_email", trimmedEmail)
            .apply()

        _authState.value = true
        _currentUserEmail.value = trimmedEmail
        return true
    }

    fun signOut() {
        prefs.edit().remove("session_email").apply()
        _authState.value = false
        _currentUserEmail.value = null
    }

    fun isAuthenticated(): Boolean {
        return prefs.getString("session_email", null) != null
    }

    private fun loadCurrentEmail(): String? {
        return prefs.getString("session_email", null)
    }

    private fun generateSalt(): String {
        val bytes = ByteArray(16)
        SecureRandom().nextBytes(bytes)
        return bytes.joinToString("") { "%02x".format(it) }
    }

    private fun hashPassword(password: String, salt: String): String {
        val input = "$salt$password"
        val digest = MessageDigest.getInstance("SHA-256")
        val hashBytes = digest.digest(input.toByteArray(Charsets.UTF_8))
        return hashBytes.joinToString("") { "%02x".format(it) }
    }
}
