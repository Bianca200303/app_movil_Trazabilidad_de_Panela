# Widget Component System

Este documento describe el sistema de componentes reutilizables implementado en la aplicación Panela Sys, siguiendo las mejores prácticas de Flutter.

## Arquitectura de Componentes

### 1. **Estructura de Directorios**

```
lib/widgets/
├── common/           # Componentes UI generales
├── forms/           # Componentes de formularios
├── data/            # Componentes para manejo de datos
└── widgets.dart     # Barrel file para imports

lib/core/theme/
├── app_colors.dart      # Colores de la aplicación
├── app_text_styles.dart # Estilos de texto
└── app_dimensions.dart  # Dimensiones y espaciado
```

### 2. **Principios de Diseño**

- **Reutilización**: Todos los componentes están diseñados para ser reutilizables
- **Consistencia**: Uso de theme system para mantener coherencia visual
- **Composición**: Los componentes se pueden combinar para crear interfaces complejas
- **Flexibilidad**: Parámetros opcionales para customización
- **Mantenibilidad**: Código limpio y bien documentado

## Componentes Principales

### **AppScaffold**
```dart
AppScaffold(
  hasTopLabel: true,
  topLabelText: 'Inicio',
  showBackButton: true,
  onBack: () => Navigator.pop(context),
  child: // contenido
)
```
- Maneja el background brown y la imagen de fondo
- Top label opcional
- Back button opcional
- SafeArea incluido

### **AppCard**
```dart
AppCard(
  hasBackButton: true,
  onBack: () => Navigator.pop(context),
  child: // contenido
)
```
- Card semi-transparente con bordes redondeados
- Back button opcional integrado
- Padding consistente

### **AppButton**
```dart
AppButton(
  text: 'Botón',
  type: AppButtonType.primary,
  icon: Icons.person,
  onPressed: () {},
  isLoading: false,
)
```

**Tipos disponibles:**
- `primary`: Botón azul principal
- `secondary`: Botón con borde azul
- `back`: Botón rojo para regresar
- `option`: Botón de opción inactivo
- `optionActive`: Botón de opción activo
- `exitType`: Botón para tipos de salida

### **AppTextField**
```dart
AppTextField(
  label: 'Campo',
  controller: controller,
  validator: validator,
  keyboardType: TextInputType.number,
  maxLength: 8,
  suffixIcon: Icon(Icons.visibility),
)
```
- Label automático arriba del campo
- Validación integrada
- Estilos consistentes

### **AppDropdownField**
```dart
AppDropdownField<String>(
  label: 'Seleccionar',
  value: selectedValue,
  items: items,
  onChanged: (value) {},
)
```

### **FormGroup & FormSection**
```dart
FormGroup(
  spacing: 16.0,
  children: [
    AppTextField(...),
    AppButton(...),
  ],
)

FormSection(
  title: 'Datos Personales',
  subtitle: 'Información básica del usuario',
  children: [...],
)
```

### **AppTitle & Variantes**
```dart
AppTitle(title: 'Título Principal')
SectionTitle(title: 'Sección')
CardTitle(title: 'Card')
```

### **AppRadioGroup & AppCheckboxGroup**
```dart
AppRadioGroup<String>(
  label: 'Condición',
  options: [
    RadioOption(value: 'SOCIO', label: 'SOCIO'),
    RadioOption(value: 'NO SOCIO', label: 'NO SOCIO'),
  ],
  groupValue: selectedValue,
  onChanged: (value) {},
)
```

### **DataTableWidget**
```dart
DataTableWidget(
  headers: ['Nombre', 'Módulo', 'Condición'],
  data: [
    ['Juan Pérez', 'Tailin', 'Socio'],
    ['María García', 'Tailin', 'No Socio'],
  ],
  flexValues: [2, 1, 1], // Opcional: control de anchura columnas
)
```

## Sistema de Theming

### **Colores (AppColors)**
```dart
AppColors.primary          // Azul principal (#0066BB)
AppColors.backgroundBrown  // Marrón de fondo (#8B5A2B)
AppColors.backButtonRed    // Rojo del botón regresar
AppColors.cardBackground   // Blanco de cards
AppColors.inputFill        // Blanco de inputs
```

### **Estilos de Texto (AppTextStyles)**
```dart
AppTextStyles.mainTitle      // Título principal (36px, bold)
AppTextStyles.sectionTitle   // Título de sección (28px, bold)
AppTextStyles.fieldLabel     // Labels de campos (18px, medium)
AppTextStyles.buttonText     // Texto de botones (18px, bold)
AppTextStyles.linkText       // Enlaces (16px, azul)
```

### **Dimensiones (AppDimensions)**
```dart
AppDimensions.spacingMedium     // 16.0
AppDimensions.paddingLarge      // 20.0
AppDimensions.radiusMedium      // 8.0
AppDimensions.iconMedium        // 28.0
```

## Ejemplo de Uso Completo

```dart
class ExampleScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      hasTopLabel: true,
      topLabelText: 'Ejemplo',
      child: AppCard(
        hasBackButton: true,
        child: FormGroup(
          children: [
            const AppTitle(title: 'Formulario de Ejemplo'),
            
            FormSection(
              title: 'Datos Personales',
              children: [
                AppTextField(
                  label: 'Nombre',
                  controller: nameController,
                ),
                AppDropdownField<String>(
                  label: 'Cargo',
                  value: selectedRole,
                  items: roleItems,
                  onChanged: (value) => setState(() => selectedRole = value),
                ),
              ],
            ),
            
            AppButton(
              text: 'Guardar',
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
```

## Migración de Pantallas Existentes

### Antes:
```dart
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
              color: Colors.white.withOpacity(0.9),
              // ... más código repetitivo
```

### Después:
```dart
return AppScaffold(
  child: AppCard(
    child: FormGroup(
      children: [
        // componentes limpios y reutilizables
      ],
    ),
  ),
);
```

## Beneficios del Sistema

1. **Reducción de Código**: ~70% menos líneas de código en las pantallas
2. **Consistencia Visual**: Theme system garantiza coherencia
3. **Mantenibilidad**: Cambios centralizados en componentes
4. **Testing**: Componentes aislados fáciles de testear
5. **Performance**: Widgets reutilizables optimizados
6. **Escalabilidad**: Fácil agregar nuevos componentes

## Próximos Pasos

- [ ] Migrar todas las pantallas existentes
- [ ] Añadir más variantes de componentes según necesidades
- [ ] Implementar testing para cada componente
- [ ] Documentar patrones de navegación
- [ ] Crear componentes específicos del dominio (ProductorCard, etc.)