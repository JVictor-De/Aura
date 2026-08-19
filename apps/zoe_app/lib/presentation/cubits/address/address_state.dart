part of 'address_cubit.dart';

abstract class AddressState {
  const AddressState();
}

class AddressInitial extends AddressState {
  const AddressInitial();
}

class AddressSelected extends AddressState {
  final Address address;
  final double lat;
  final double lng;

  const AddressSelected({
    required this.address,
    required this.lat,
    required this.lng,
  });
}
