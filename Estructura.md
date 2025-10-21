TFG/
├── lib/
│   ├── main.dart                      # Punto de entrada de la app
│   │
│   ├── screens/                       # 🖥️ PANTALLAS
│   │   ├── home/
│   │   │   └── home_screen.dart
│   │   ├── login/
│   │   │   └── login_screen.dart
│   │   ├── register/
│   │   │   └── register_screen.dart
│   │   └── profile/
│   │       └── profile_screen.dart
│   │
│   ├── widgets/                       # 🧩 COMPONENTES REUTILIZABLES
│   │   ├── buttons/
│   │   │   └── custom_button.dart
│   │   ├── cards/
│   │   │   └── custom_card.dart
│   │   └── inputs/
│   │       └── custom_input.dart
│   │
│   ├── models/                        # 📦 MODELOS DE DATOS
│   │   ├── user.dart
│   │   └── ...otros modelos
│   │
│   ├── services/                      # ⚙️ LÓGICA DE NEGOCIO
│   │   ├── api_service.dart          # Llamadas a API
│   │   ├── auth_service.dart         # Autenticación
│   │   └── database_service.dart     # Base de datos local
│   │
│   ├── providers/                     # 🔄 GESTIÓN DE ESTADO
│   │   ├── user_provider.dart        # Estado del usuario
│   │   └── theme_provider.dart       # Estado del tema
│   │
│   ├── utils/                         # 🛠️ UTILIDADES
│   │   ├── constants.dart            # Constantes (colores, textos, URLs)
│   │   ├── validators.dart           # Validaciones de formularios
│   │   └── helpers.dart              # Funciones auxiliares
│   │
│   └── config/                        # ⚙️ CONFIGURACIÓN
│       ├── routes.dart               # Rutas de navegación
│       ├── theme.dart                # Estilos y temas
│       └── app_config.dart           # Config general (API keys, etc)
│
├── assets/                            # 📂 RECURSOS ESTÁTICOS
│   ├── images/                       # Imágenes
│   ├── icons/                        # Iconos personalizados
│   └── fonts/                        # Fuentes personalizadas
│
├── test/                             # 🧪 TESTS
│   └── widget_test.dart
│
├── android/                          # Configuración Android
├── ios/                              # Configuración iOS
├── web/                              # Configuración Web
├── pubspec.yaml                      # Dependencias y assets
└── README.md