import { useState } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  Alert,
  KeyboardAvoidingView,
  Platform,
  ScrollView,
} from 'react-native';
import { Coffee, User, Lock, LogIn } from 'lucide-react-native';
import { useAuth } from '@/lib/AuthContext';

export default function LoginScreen() {
  const { login } = useAuth();
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [isLoading, setIsLoading] = useState(false);

  const handleLogin = async () => {
    if (!username.trim()) {
      Alert.alert('Error', 'Please enter your username');
      return;
    }
    if (!password.trim()) {
      Alert.alert('Error', 'Please enter your password');
      return;
    }

    setIsLoading(true);
    const result = await login(username, password);
    setIsLoading(false);

    if (!result.success) {
      Alert.alert('Login Failed', result.error || 'Invalid credentials');
    }
  };

  return (
    <KeyboardAvoidingView 
      style={styles.container} 
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
    >
      <ScrollView 
        contentContainerStyle={styles.scrollContent}
        keyboardShouldPersistTaps="handled"
      >
        {/* Logo Section */}
        <View style={styles.logoSection}>
          <View style={styles.logoContainer}>
            <Coffee size={48} color="#FFFFFF" />
          </View>
          <Text style={styles.appName}>Order System</Text>
          <Text style={styles.tagline}>Showroom Beverages</Text>
        </View>

        {/* Login Form */}
        <View style={styles.formContainer}>
          <Text style={styles.welcomeText}>Welcome Back</Text>
          <Text style={styles.instructionText}>Sign in to continue</Text>

          {/* Username Input */}
          <View style={styles.inputContainer}>
            <User size={20} color="#64748B" style={styles.inputIcon} />
            <TextInput
              style={styles.input}
              placeholder="Username"
              placeholderTextColor="#94A3B8"
              value={username}
              onChangeText={setUsername}
              autoCapitalize="none"
              autoCorrect={false}
            />
          </View>

          {/* Password Input */}
          <View style={styles.inputContainer}>
            <Lock size={20} color="#64748B" style={styles.inputIcon} />
            <TextInput
              style={styles.input}
              placeholder="Password"
              placeholderTextColor="#94A3B8"
              value={password}
              onChangeText={setPassword}
              secureTextEntry
            />
          </View>

          {/* Login Button */}
          <TouchableOpacity
            style={[styles.loginButton, isLoading && styles.loginButtonDisabled]}
            onPress={handleLogin}
            disabled={isLoading}
          >
            <LogIn size={20} color="#FFFFFF" />
            <Text style={styles.loginButtonText}>
              {isLoading ? 'Signing in...' : 'Sign In'}
            </Text>
          </TouchableOpacity>

          {/* Demo Credentials */}
          <View style={styles.demoSection}>
            <Text style={styles.demoTitle}>Demo Accounts</Text>
            <View style={styles.demoCredentials}>
              <View style={styles.demoRole}>
                <Text style={styles.demoRoleTitle}>👤 Salesperson</Text>
                <Text style={styles.demoText}>sales1 / 1234</Text>
              </View>
              <View style={styles.demoRole}>
                <Text style={styles.demoRoleTitle}>👨‍🍳 Kitchen</Text>
                <Text style={styles.demoText}>kitchen1 / 1234</Text>
              </View>
            </View>
          </View>
        </View>
      </ScrollView>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#0EA5E9',
  },
  scrollContent: {
    flexGrow: 1,
  },
  logoSection: {
    alignItems: 'center',
    paddingTop: 80,
    paddingBottom: 40,
  },
  logoContainer: {
    width: 100,
    height: 100,
    borderRadius: 50,
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 16,
  },
  appName: {
    fontSize: 28,
    fontWeight: '700',
    color: '#FFFFFF',
  },
  tagline: {
    fontSize: 16,
    color: 'rgba(255, 255, 255, 0.8)',
    marginTop: 4,
  },
  formContainer: {
    flex: 1,
    backgroundColor: '#FFFFFF',
    borderTopLeftRadius: 32,
    borderTopRightRadius: 32,
    paddingHorizontal: 24,
    paddingTop: 32,
    paddingBottom: 40,
  },
  welcomeText: {
    fontSize: 24,
    fontWeight: '700',
    color: '#1E293B',
    textAlign: 'center',
  },
  instructionText: {
    fontSize: 16,
    color: '#64748B',
    textAlign: 'center',
    marginTop: 8,
    marginBottom: 32,
  },
  inputContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#F1F5F9',
    borderRadius: 12,
    marginBottom: 16,
    paddingHorizontal: 16,
  },
  inputIcon: {
    marginRight: 12,
  },
  input: {
    flex: 1,
    height: 52,
    fontSize: 16,
    color: '#1E293B',
  },
  loginButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#0EA5E9',
    borderRadius: 12,
    paddingVertical: 16,
    marginTop: 8,
    gap: 8,
  },
  loginButtonDisabled: {
    backgroundColor: '#94A3B8',
  },
  loginButtonText: {
    fontSize: 18,
    fontWeight: '700',
    color: '#FFFFFF',
  },
  demoSection: {
    marginTop: 32,
    padding: 16,
    backgroundColor: '#F8FAFC',
    borderRadius: 12,
  },
  demoTitle: {
    fontSize: 14,
    fontWeight: '600',
    color: '#64748B',
    textAlign: 'center',
    marginBottom: 12,
  },
  demoCredentials: {
    flexDirection: 'row',
    justifyContent: 'space-around',
  },
  demoRole: {
    alignItems: 'center',
  },
  demoRoleTitle: {
    fontSize: 14,
    fontWeight: '600',
    color: '#1E293B',
    marginBottom: 4,
  },
  demoText: {
    fontSize: 13,
    color: '#64748B',
    fontFamily: Platform.OS === 'ios' ? 'Menlo' : 'monospace',
  },
});
