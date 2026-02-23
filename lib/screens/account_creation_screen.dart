import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:panela_sys/screens/home_screen.dart';
import 'package:panela_sys/widgets/common/app_back_button.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';

class AccountCreationScreen extends StatefulWidget {
  const AccountCreationScreen({super.key});

  @override
  State<AccountCreationScreen> createState() => _AccountCreationScreenState();
}

class _AccountCreationScreenState extends State<AccountCreationScreen> {
  final TextEditingController _namesController = TextEditingController();
  final TextEditingController _surnamesController = TextEditingController();
  final TextEditingController _dniController = TextEditingController();
  String _selectedRole = '';
  final List<String> _roleOptions = ['Administrador', 'Usuario', 'Supervisor'];

  @override
  void dispose() {
    _namesController.dispose();
    _surnamesController.dispose();
    _dniController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF8B5A2B),
          image: _buildBackgroundImage(),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Card(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Back button
                        AppBackButton(
                          onPressed: () => Navigator.pop(context),
                          isExpanded: true,
                        ),
                        const SizedBox(height: 16),
                        
                        // Title
                        Text(
                          'Crear cuenta',
                          style: AppTextStyles.mainTitle,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        
                        // Names field
                        const Text(
                          'Nombres',
                          style: AppTextStyles.fieldLabel,
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _namesController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Surnames field
                        const Text(
                          'Apellidos',
                          style: AppTextStyles.fieldLabel,
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _surnamesController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // DNI field
                        const Text(
                          'Número de DNI',
                          style: AppTextStyles.fieldLabel,
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _dniController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Role dropdown
                        const Text(
                          'Cargo',
                          style: AppTextStyles.fieldLabel,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: DropdownButtonFormField<String>(
                            value: _selectedRole.isEmpty ? null : _selectedRole,
                            hint: const Text('Seleccionar cargo'),
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(horizontal: 16),
                              border: InputBorder.none,
                            ),
                            icon: const Icon(Icons.keyboard_arrow_down),
                            items: _roleOptions.map((String role) {
                              return DropdownMenuItem<String>(
                                value: role,
                                child: Text(role),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedRole = newValue!;
                              });
                            },
                            isExpanded: true,
                          ),
                        ),
                        const SizedBox(height: 48),
                        
                        // Register button
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context)=> const HomeScreen()));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0066BB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          child: const Text(
                            'REGISTRAR',
                            style: AppTextStyles.buttonText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to build background image with fallback
  DecorationImage? _buildBackgroundImage() {
    try {
      return DecorationImage(
        image: const AssetImage('assets/bread_background.jpg'),
        fit: BoxFit.cover,
        onError: (exception, stackTrace) {
          if (kDebugMode) {
            debugPrint('Failed to load background image: $exception');
          }
          return;
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading background image: $e');
      }
      return null;
    }
  }
}