import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:zoe_portal/domain/entities/store_settings.dart';
import 'package:zoe_portal/domain/services/portal_settings_service.dart';

// ─── States ──────────────────────────────────────────────────────────

abstract class PortalSettingsState extends Equatable {
  const PortalSettingsState();

  @override
  List<Object?> get props => [];
}

class PortalSettingsInitial extends PortalSettingsState {
  const PortalSettingsInitial();
}

class PortalSettingsLoading extends PortalSettingsState {
  const PortalSettingsLoading();
}

class PortalSettingsLoaded extends PortalSettingsState {
  final StoreSettings settings;

  const PortalSettingsLoaded(this.settings);

  @override
  List<Object?> get props => [settings];
}

class PortalSettingsSaved extends PortalSettingsState {
  final StoreSettings settings;

  const PortalSettingsSaved(this.settings);

  @override
  List<Object?> get props => [settings];
}

class PortalSettingsError extends PortalSettingsState {
  final String message;

  const PortalSettingsError(this.message);

  @override
  List<Object?> get props => [message];
}

// ─── Cubit ───────────────────────────────────────────────────────────

class PortalSettingsCubit extends Cubit<PortalSettingsState> {
  final PortalSettingsService _settingsService;

  PortalSettingsCubit({required PortalSettingsService settingsService})
      : _settingsService = settingsService,
        super(const PortalSettingsInitial());

  /// Carrega as configurações atuais da loja.
  Future<void> loadSettings() async {
    emit(const PortalSettingsLoading());
    try {
      final settings = await _settingsService.getSettings();
      emit(PortalSettingsLoaded(settings));
    } catch (e) {
      emit(PortalSettingsError(e.toString()));
    }
  }

  /// Salva as configurações da loja e emite [PortalSettingsSaved].
  Future<void> saveSettings(Map<String, dynamic> data) async {
    emit(const PortalSettingsLoading());
    try {
      final updated = await _settingsService.updateSettings(data);
      emit(PortalSettingsSaved(updated));
    } catch (e) {
      emit(PortalSettingsError(e.toString()));
    }
  }
}
