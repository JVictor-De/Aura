/// AddressCubit — geolocalização first, filtro global por coordenadas.
///
/// Referência: ARCHITECTURE.md §2.1: Geolocalização First (Multi-Endereços)
import 'package:hydrated_bloc/hydrated_bloc.dart';

import '../../../domain/entities/address.dart';

part 'address_state.dart';

class AddressCubit extends HydratedCubit<AddressState> {
  AddressCubit() : super(const AddressInitial());

  void setCurrentAddress(Address address) {
    emit(AddressSelected(
      address: address,
      lat: address.latitude ?? 0,
      lng: address.longitude ?? 0,
    ));
  }

  void setCoordinates(double lat, double lng, String label) {
    final address = Address(
      id: 'gps-${DateTime.now().millisecondsSinceEpoch}',
      label: label,
      street: label,
      number: '',
      neighborhood: '',
      city: '',
      state: '',
      zipCode: '',
      latitude: lat,
      longitude: lng,
      isDefault: true,
    );
    emit(AddressSelected(address: address, lat: lat, lng: lng));
  }

  void clearAddress() {
    emit(const AddressInitial());
  }

  double? get currentLat {
    final s = state;
    return s is AddressSelected ? s.lat : null;
  }

  double? get currentLng {
    final s = state;
    return s is AddressSelected ? s.lng : null;
  }

  @override
  AddressState? fromJson(Map<String, dynamic> json) {
    try {
      if (json['has_address'] != true) return const AddressInitial();
      return AddressSelected(
        address: Address(
          id: json['address_id'] as String? ?? '',
          label: json['label'] as String? ?? '',
          street: json['street'] as String? ?? '',
          number: json['number'] as String? ?? '',
          neighborhood: json['neighborhood'] as String? ?? '',
          city: json['city'] as String? ?? '',
          state: json['state'] as String? ?? '',
          zipCode: json['zip_code'] as String? ?? '',
          latitude: (json['lat'] as num?)?.toDouble(),
          longitude: (json['lng'] as num?)?.toDouble(),
          isDefault: true,
        ),
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
      );
    } catch (_) {
      return const AddressInitial();
    }
  }

  @override
  Map<String, dynamic>? toJson(AddressState state) {
    if (state is AddressSelected) {
      return {
        'has_address': true,
        'address_id': state.address.id,
        'label': state.address.label,
        'street': state.address.street,
        'city': state.address.city,
        'state': state.address.state,
        'zip_code': state.address.zipCode,
        'lat': state.lat,
        'lng': state.lng,
      };
    }
    return {'has_address': false};
  }
}
