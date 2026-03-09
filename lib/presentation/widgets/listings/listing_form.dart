import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:kigali_connect/config/theme.dart';
import 'package:kigali_connect/domain/models/enums.dart';
import 'package:kigali_connect/domain/validators/listing_validator.dart';
import 'package:kigali_connect/presentation/widgets/common/app_button.dart';
import 'package:kigali_connect/presentation/widgets/common/app_text_field.dart';

class ListingFormData {
  const ListingFormData({
    required this.name,
    required this.category,
    required this.address,
    required this.contactNumber,
    required this.description,
    required this.latitude,
    required this.longitude,
  });

  final String name;
  final PlaceCategory category;
  final String address;
  final String contactNumber;
  final String description;
  final double latitude;
  final double longitude;
}

class ListingForm extends StatefulWidget {
  const ListingForm({
    super.key,
    this.initial,
    required this.onSubmit,
    required this.isLoading,
    required this.submitLabel,
  });

  final ListingFormData? initial;
  final void Function(ListingFormData) onSubmit;
  final bool isLoading;
  final String submitLabel;

  @override
  State<ListingForm> createState() => _ListingFormState();
}

class _ListingFormState extends State<ListingForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _latCtrl;
  late final TextEditingController _lngCtrl;
  late PlaceCategory _category;
  bool _isGeocoding = false;

  @override
  void initState() {
    super.initState();
    final d = widget.initial;
    _nameCtrl    = TextEditingController(text: d?.name ?? '');
    _addressCtrl = TextEditingController(text: d?.address ?? '');
    _phoneCtrl   = TextEditingController(text: d?.contactNumber ?? '');
    _descCtrl    = TextEditingController(text: d?.description ?? '');
    _latCtrl     = TextEditingController(text: d?.latitude.toString() ?? '');
    _lngCtrl     = TextEditingController(text: d?.longitude.toString() ?? '');
    _category    = d?.category ?? PlaceCategory.values.first;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _descCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  Future<void> _geocodeAddress() async {
    final address = _addressCtrl.text.trim();
    if (address.isEmpty) return;
    setState(() => _isGeocoding = true);
    try {
      final locations = await locationFromAddress(address);
      if (locations.isNotEmpty && mounted) {
        setState(() {
          _latCtrl.text = locations.first.latitude.toStringAsFixed(6);
          _lngCtrl.text = locations.first.longitude.toStringAsFixed(6);
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not find coordinates for that address.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeocoding = false);
    }
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    widget.onSubmit(ListingFormData(
      name:          _nameCtrl.text.trim(),
      category:      _category,
      address:       _addressCtrl.text.trim(),
      contactNumber: _phoneCtrl.text.trim(),
      description:   _descCtrl.text.trim(),
      latitude:      double.parse(_latCtrl.text.trim()),
      longitude:     double.parse(_lngCtrl.text.trim()),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            controller: _nameCtrl,
            label: 'Place Name',
            validator: ListingValidator.validateName,
          ),
          const SizedBox(height: AppSpacing.p16),

          // Category dropdown
          DropdownButtonFormField<PlaceCategory>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Category'),
            items: PlaceCategory.values.map((cat) {
              return DropdownMenuItem(
                value: cat,
                child: Row(
                  children: [
                    Icon(cat.iconData, size: 18, color: cat.iconColor),
                    const SizedBox(width: AppSpacing.p8),
                    Text(cat.displayName),
                  ],
                ),
              );
            }).toList(),
            onChanged: (v) {
              if (v != null) setState(() => _category = v);
            },
          ),
          const SizedBox(height: AppSpacing.p16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppTextField(
                  controller: _addressCtrl,
                  label: 'Address',
                  validator: ListingValidator.validateAddress,
                ),
              ),
              const SizedBox(width: AppSpacing.p8),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Tooltip(
                  message: 'Auto-fill coordinates from address',
                  child: _isGeocoding
                      ? const SizedBox(
                          width: 48,
                          height: 48,
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        )
                      : IconButton.filled(
                          icon: const Icon(Icons.my_location),
                          onPressed: _geocodeAddress,
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.p16),

          AppTextField(
            controller: _phoneCtrl,
            label: 'Contact Number',
            keyboardType: TextInputType.phone,
            validator: ListingValidator.validateContactNumber,
          ),
          const SizedBox(height: AppSpacing.p16),

          AppTextField(
            controller: _descCtrl,
            label: 'Description',
            maxLines: 4,
            validator: ListingValidator.validateDescription,
          ),
          const SizedBox(height: AppSpacing.p16),

          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: _latCtrl,
                  label: 'Latitude',
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: true, decimal: true,
                  ),
                  validator: ListingValidator.validateLatitude,
                ),
              ),
              const SizedBox(width: AppSpacing.p12),
              Expanded(
                child: AppTextField(
                  controller: _lngCtrl,
                  label: 'Longitude',
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: true, decimal: true,
                  ),
                  validator: ListingValidator.validateLongitude,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.p24),

          AppButton(
            label: widget.submitLabel,
            isLoading: widget.isLoading,
            onPressed: widget.isLoading ? null : _submit,
          ),
        ],
      ),
    );
  }
}
