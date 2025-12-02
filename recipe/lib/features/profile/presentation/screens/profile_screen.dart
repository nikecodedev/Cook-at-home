import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/standard_app_bar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../providers/profile_provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../models/profile_model.dart';
import '../../../../core/utils/validators.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _locationController;
  late TextEditingController _servingSizeController;
  String _unitPreference = 'metric';
  List<HouseholdMember> _householdMembers = [];
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _locationController = TextEditingController();
    _servingSizeController = TextEditingController(text: '4');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _locationController.dispose();
    _servingSizeController.dispose();
    super.dispose();
  }

  void _loadProfileData(ProfileModel? profile) {
    if (profile != null) {
      _nameController.text = profile.name;
      _emailController.text = profile.email;
      _locationController.text = profile.location ?? '';
      _servingSizeController.text = profile.servingSize.toString();
      _unitPreference = profile.unitPreference;
      _householdMembers = List.from(profile.householdMembers);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay usuario conectado'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    try {
      final servingSize = int.tryParse(_servingSizeController.text) ?? 4;

      await ref.read(profileControllerProvider.notifier).updateProfile(
            userId: userId,
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            location: _locationController.text.trim().isEmpty
                ? null
                : _locationController.text.trim(),
            unitPreference: _unitPreference,
            servingSize: servingSize,
            householdMembers: _householdMembers,
          );

      if (mounted) {
        setState(() {
          _isEditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil actualizado exitosamente'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        if (errorMessage.contains('Exception: ')) {
          errorMessage = errorMessage.replaceFirst('Exception: ', '');
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar el perfil: ${errorMessage.length > 100 ? errorMessage.substring(0, 100) + "..." : errorMessage}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Descartar',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }

  void _addHouseholdMember() {
    showDialog(
      context: context,
      builder: (context) => _AddHouseholdMemberDialog(
        onSave: (member) {
          setState(() {
            _householdMembers.add(member);
          });
        },
      ),
    );
  }

  void _editHouseholdMember(int index) {
    final member = _householdMembers[index];
    showDialog(
      context: context,
      builder: (context) => _AddHouseholdMemberDialog(
        initialMember: member,
        onSave: (updatedMember) {
          setState(() {
            _householdMembers[index] = updatedMember;
          });
        },
      ),
    );
  }

  void _removeHouseholdMember(int index) {
    setState(() {
      _householdMembers.removeAt(index);
    });
  }

  String _translateRelationship(String? relationship) {
    if (relationship == null) return '';
    switch (relationship) {
      case 'spouse':
        return 'Cónyuge';
      case 'child':
        return 'Hijo/a';
      case 'parent':
        return 'Padre/Madre';
      case 'sibling':
        return 'Hermano/a';
      case 'other':
        return 'Otro';
      default:
        return relationship;
    }
  }

  Future<void> _createProfileIfNeeded() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    final firestoreService = ref.read(firestoreServiceProvider);
    final profileExists = await firestoreService.userProfileExists(userId);

    if (!profileExists) {
      // Get user email from auth
      final authState = ref.read(authStateProvider);
      final email = authState.value?.email ?? '';
      final String displayName = (authState.value?.displayName?.isNotEmpty == true
          ? authState.value!.displayName!
          : (email.isNotEmpty && email.contains('@') 
              ? email.split('@')[0] 
              : 'Usuario'));

      try {
        await ref.read(profileControllerProvider.notifier).createProfile(
              userId: userId,
              name: displayName,
              email: email,
              location: null,
              unitPreference: 'metric',
              servingSize: 4,
              householdMembers: [],
            );
        // Refresh the profile stream
        ref.invalidate(profileStreamProvider);
      } catch (e) {
        if (mounted) {
          String errorMessage = e.toString();
          if (errorMessage.contains('Exception: ')) {
            errorMessage = errorMessage.replaceFirst('Exception: ', '');
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al crear el perfil: ${errorMessage.length > 100 ? errorMessage.substring(0, 100) + "..." : errorMessage}'),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Descartar',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileStreamProvider);
    final isLoading = ref.watch(profileControllerProvider).isLoading;

    return Scaffold(
      appBar: StandardAppBar(
        title: 'Perfil',
        showBackButton: true,
        actions: [
          if (!_isEditing)
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _isEditing = true;
                  });
                },
              ),
            )
          else
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _isEditing = false;
                  });
                  // Reload profile data
                  profileAsync.whenData(_loadProfileData);
                },
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) {
          // Auto-create profile if it doesn't exist
          if (profile == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _createProfileIfNeeded();
            });
            return const Center(child: CircularProgressIndicator());
          }

          if (profile != null && !_isEditing) {
            _loadProfileData(profile);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Profile Header
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            child: Text(
                              _nameController.text.isNotEmpty
                                  ? _nameController.text[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _nameController.text.isNotEmpty
                                ? _nameController.text
                                : 'Usuario',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Name Field
                  CustomTextField(
                    label: 'Nombre',
                    controller: _nameController,
                    enabled: _isEditing,
                    prefixIcon: Icons.person_outline,
                    validator: Validators.validateName,
                  ),

                  const SizedBox(height: 16),

                  // Email Field
                  CustomTextField(
                    label: 'Correo electrónico',
                    controller: _emailController,
                    enabled: _isEditing,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    validator: Validators.validateEmail,
                  ),

                  const SizedBox(height: 16),

                  // Location Field
                  CustomTextField(
                    label: 'Ubicación (Opcional)',
                    controller: _locationController,
                    enabled: _isEditing,
                    prefixIcon: Icons.location_on_outlined,
                    hint: 'Ingresa tu ubicación',
                  ),

                  const SizedBox(height: 16),

                  // Unit Preference
                  if (_isEditing) ...[
                    const Text(
                      'Preferencia de Unidad',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'metric',
                          label: Text('Métrico'),
                          icon: Icon(Icons.straighten),
                        ),
                        ButtonSegment(
                          value: 'imperial',
                          label: Text('Imperial'),
                          icon: Icon(Icons.straighten_outlined),
                        ),
                      ],
                      selected: {_unitPreference},
                      onSelectionChanged: (Set<String> newSelection) {
                        setState(() {
                          _unitPreference = newSelection.first;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.straighten),
                        title: const Text('Preferencia de Unidades'),
                        subtitle: Text(
                          _unitPreference == 'metric' ? 'Métrico' : 'Imperial',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Serving Size
                  CustomTextField(
                    label: 'Tamaño de Porción por Defecto',
                    controller: _servingSizeController,
                    enabled: _isEditing,
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.restaurant_outlined,
                    validator: (value) {
                      if (!_isEditing) return null;
                      final error = Validators.validateInteger(value, 'Serving size');
                      if (error != null) return error;
                      final size = int.tryParse(value ?? '');
                      if (size != null && (size < 1 || size > 20)) {
                        return 'El tamaño de porción debe estar entre 1 y 20';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // Household Members Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Miembros del Hogar',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (_isEditing)
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: _addHouseholdMember,
                          color: AppColors.primary,
                        ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  if (_householdMembers.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Aún no se han añadido miembros del hogar',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    ..._householdMembers.asMap().entries.map((entry) {
                      final index = entry.key;
                      final member = entry.value;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              member.name.isNotEmpty 
                                  ? member.name[0].toUpperCase() 
                                  : '?',
                            ),
                          ),
                          title: Text(member.name),
                          subtitle: Text(
                            [
                              if (member.relationship != null)
                                _translateRelationship(member.relationship),
                              if (member.age != null) 'Edad: ${member.age}',
                            ].join(' • '),
                          ),
                          trailing: _isEditing
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () => _editHouseholdMember(index),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      color: AppColors.error,
                                      onPressed: () => _removeHouseholdMember(index),
                                    ),
                                  ],
                                )
                              : null,
                        ),
                      );
                    }),

                  const SizedBox(height: 24),

                  // Save Button
                  if (_isEditing)
                    CustomButton(
                      text: 'Guardar Perfil',
                      onPressed: isLoading ? null : _saveProfile,
                      isLoading: isLoading,
                      icon: Icons.save,
                    ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error al cargar el perfil: $error',
                style: const TextStyle(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: 'Reintentar',
                onPressed: () {
                  ref.invalidate(profileStreamProvider);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddHouseholdMemberDialog extends StatefulWidget {
  final HouseholdMember? initialMember;
  final Function(HouseholdMember) onSave;

  const _AddHouseholdMemberDialog({
    this.initialMember,
    required this.onSave,
  });

  @override
  State<_AddHouseholdMemberDialog> createState() =>
      _AddHouseholdMemberDialogState();
}

class _AddHouseholdMemberDialogState extends State<_AddHouseholdMemberDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  String? _relationship;

  final List<String> _relationships = [
    'spouse',
    'child',
    'parent',
    'sibling',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialMember?.name ?? '',
    );
    _ageController = TextEditingController(
      text: widget.initialMember?.age?.toString() ?? '',
    );
    _relationship = widget.initialMember?.relationship;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final member = HouseholdMember(
      id: widget.initialMember?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      relationship: _relationship,
      age: _ageController.text.trim().isEmpty
          ? null
          : int.tryParse(_ageController.text.trim()),
    );

    widget.onSave(member);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialMember == null
          ? 'Agregar Miembro del Hogar'
          : 'Editar Miembro del Hogar'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                label: 'Nombre',
                controller: _nameController,
                prefixIcon: Icons.person_outline,
                validator: Validators.validateName,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _relationship,
                decoration: const InputDecoration(
                  labelText: 'Relación (Opcional)',
                  prefixIcon: Icon(Icons.people_outline),
                ),
                items: _relationships.map((rel) {
                  String displayText;
                  switch (rel) {
                    case 'spouse':
                      displayText = 'Cónyuge';
                      break;
                    case 'child':
                      displayText = 'Hijo/a';
                      break;
                    case 'parent':
                      displayText = 'Padre/Madre';
                      break;
                    case 'sibling':
                      displayText = 'Hermano/a';
                      break;
                    case 'other':
                      displayText = 'Otro';
                      break;
                    default:
                      displayText = rel;
                  }
                  return DropdownMenuItem(
                    value: rel,
                    child: Text(displayText),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _relationship = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Edad (Opcional)',
                controller: _ageController,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.cake_outlined,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final age = int.tryParse(value);
                    if (age == null) {
                      return 'Por favor ingresa una edad válida';
                    }
                    if (age < 0 || age > 150) {
                      return 'La edad debe estar entre 0 y 150';
                    }
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

