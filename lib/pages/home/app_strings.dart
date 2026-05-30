class AppStrings {
  static String _currentLanguage = 'en';

  static void setLanguage(String code) {
    _currentLanguage = code;
  }

  static String get currentLanguage => _currentLanguage;

  static final Map<String, Map<String, String>> _strings = {
    'en': {
      // Auth
      'welcome': 'Welcome to ZapZap',
      'enter_phone': 'Please enter your phone number to continue',
      'login': 'Login',
      'login_qr': 'Login with QR Code',
      'code_sent': 'The code was sent to your phone number',
      'input_code': 'Input Code',
      'verify': 'Verify',
      'input_code_error': 'Input the code',
      'invalid_code': 'Invalid code',
      'input_password': 'Input Password',
      'input_your_password': 'Input your password',
      'submit': 'Submit',
      'hint': 'Hint',
      // Home
      'all_chats': 'All chats',
      'search': 'Search',
      'write_message': 'Write a message...',
      'no_messages': 'No messages yet',
      'loading_messages': 'Loading older messages',
      // Menu
      'my_profile': 'My Profile',
      'new_group': 'New Group',
      'new_channel': 'New Channel',
      'contacts': 'Contacts',
      'calls': 'Calls',
      'saved_messages': 'Saved Messages',
      'settings': 'Settings',
      // Settings
      'notifications': 'Notifications and Sounds',
      'privacy': 'Privacy and Security',
      'data_storage': 'Data and Storage',
      'battery': 'Battery Saving',
      'appearance': 'Appearance',
      'language': 'Language',
      'devices': 'Devices',
      'chat_folders': 'Chat Folders',
      'about': 'About ZapZap',
      // Privacy
      'phone_number': 'Phone Number',
      'last_seen': 'Last Seen & Online',
      'profile_photos': 'Profile Photos',
      'passcode': 'Passcode Lock',
      'two_step': 'Two-Step Verification',
      'everybody': 'Everybody',
      'my_contacts': 'My contacts',
      // Language
      'language_changed': 'Language changed to',
    },
    'pt': {
      // Auth
      'welcome': 'Bem-vindo ao ZapZap',
      'enter_phone': 'Por favor, insira seu número de telefone para continuar',
      'login': 'Entrar',
      'login_qr': 'Entrar com QR Code',
      'code_sent': 'O código foi enviado para o seu número de telefone',
      'input_code': 'Inserir Código',
      'verify': 'Verificar',
      'input_code_error': 'Insira o código',
      'invalid_code': 'Código inválido',
      'input_password': 'Inserir Senha',
      'input_your_password': 'Insira sua senha',
      'submit': 'Confirmar',
      'hint': 'Dica',
      // Home
      'all_chats': 'Todas as conversas',
      'search': 'Buscar',
      'write_message': 'Escreva uma mensagem...',
      'no_messages': 'Nenhuma mensagem ainda',
      'loading_messages': 'Carregando mensagens antigas',
      // Menu
      'my_profile': 'Meu Perfil',
      'new_group': 'Novo Grupo',
      'new_channel': 'Novo Canal',
      'contacts': 'Contatos',
      'calls': 'Chamadas',
      'saved_messages': 'Mensagens Salvas',
      'settings': 'Configurações',
      // Settings
      'notifications': 'Notificações e Sons',
      'privacy': 'Privacidade e Segurança',
      'data_storage': 'Dados e Armazenamento',
      'battery': 'Economia de Bateria',
      'appearance': 'Aparência',
      'language': 'Idioma',
      'devices': 'Dispositivos',
      'chat_folders': 'Pastas de Conversa',
      'about': 'Sobre o ZapZap',
      // Privacy
      'phone_number': 'Número de Telefone',
      'last_seen': 'Visto por Último & Online',
      'profile_photos': 'Fotos de Perfil',
      'passcode': 'Bloqueio por Senha',
      'two_step': 'Verificação em Duas Etapas',
      'everybody': 'Todos',
      'my_contacts': 'Meus contatos',
      // Language
      'language_changed': 'Idioma alterado para',
    },
  };

  static String get(String key) {
    return _strings[_currentLanguage]?[key] ??
        _strings['en']?[key] ??
        key;
  }
}
