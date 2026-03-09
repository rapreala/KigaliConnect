import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kigali_connect/domain/models/enums.dart';
import 'package:kigali_connect/domain/models/listing.dart';
import 'package:kigali_connect/domain/repositories/listings_repository.dart';
import 'package:kigali_connect/presentation/blocs/listings/listings_bloc.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'listings_bloc_test.mocks.dart';

@GenerateMocks([ListingsRepository])
void main() {
  late MockListingsRepository mockRepo;

  // ── helpers ──────────────────────────────────────────────────────────────

  Listing makeListing({
    String id = 'l1',
    String name = 'Test Place',
    PlaceCategory category = PlaceCategory.park,
    String createdBy = 'uid-1',
  }) {
    final now = DateTime(2024, 1, 1);
    return Listing(
      id: id,
      name: name,
      category: category,
      address: 'KG 1 St',
      contactNumber: '+250788000001',
      description: 'A test place.',
      latitude: -1.9441,
      longitude: 30.0619,
      createdBy: createdBy,
      createdAt: now,
      updatedAt: now,
    );
  }

  ListingsLoaded makeLoaded(List<Listing> all) => ListingsLoaded(
        allListings: all,
        listings: all,
        filteredListings: all,
      );

  setUp(() {
    mockRepo = MockListingsRepository();
  });

  // ── subscription ─────────────────────────────────────────────────────────

  group('ListingsSubscriptionRequested', () {
    blocTest<ListingsBloc, ListingsState>(
      'emits [ListingsLoading, ListingsLoaded] when stream fires',
      build: () {
        when(mockRepo.watchListings())
            .thenAnswer((_) => Stream.value([makeListing()]));
        return ListingsBloc(listingsRepository: mockRepo);
      },
      act: (bloc) => bloc.add(const ListingsSubscriptionRequested()),
      expect: () => [
        const ListingsLoading(),
        makeLoaded([makeListing()]),
      ],
    );

    blocTest<ListingsBloc, ListingsState>(
      'emits [ListingsLoading, ListingsLoaded(empty)] for empty stream',
      build: () {
        when(mockRepo.watchListings())
            .thenAnswer((_) => Stream<List<Listing>>.value([]));
        return ListingsBloc(listingsRepository: mockRepo);
      },
      act: (bloc) => bloc.add(const ListingsSubscriptionRequested()),
      expect: () => [
        const ListingsLoading(),
        makeLoaded([]),
      ],
    );
  });

  // ── category filter ───────────────────────────────────────────────────────

  group('ListingsCategoryChanged', () {
    blocTest<ListingsBloc, ListingsState>(
      'filters to only selected category listings',
      build: () {
        final hospital = makeListing(id: 'h1', category: PlaceCategory.hospital);
        final park = makeListing(id: 'p1', category: PlaceCategory.park);
        when(mockRepo.watchListings())
            .thenAnswer((_) => Stream.value([hospital, park]));
        return ListingsBloc(listingsRepository: mockRepo);
      },
      act: (bloc) async {
        bloc.add(const ListingsSubscriptionRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ListingsCategoryChanged(PlaceCategory.hospital));
      },
      skip: 2, // skip Loading + initial Loaded
      expect: () {
        final hospital = makeListing(id: 'h1', category: PlaceCategory.hospital);
        final park = makeListing(id: 'p1', category: PlaceCategory.park);
        return [
          ListingsLoaded(
            allListings: [hospital, park],
            listings: [hospital],
            filteredListings: [hospital],
            selectedCategory: PlaceCategory.hospital,
          ),
        ];
      },
    );

    blocTest<ListingsBloc, ListingsState>(
      'clears filter when null category passed',
      build: () {
        final hospital = makeListing(id: 'h1', category: PlaceCategory.hospital);
        final park = makeListing(id: 'p1', category: PlaceCategory.park);
        when(mockRepo.watchListings())
            .thenAnswer((_) => Stream.value([hospital, park]));
        return ListingsBloc(listingsRepository: mockRepo);
      },
      act: (bloc) async {
        bloc.add(const ListingsSubscriptionRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ListingsCategoryChanged(PlaceCategory.hospital));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ListingsCategoryChanged(null));
      },
      skip: 3,
      expect: () {
        final hospital = makeListing(id: 'h1', category: PlaceCategory.hospital);
        final park = makeListing(id: 'p1', category: PlaceCategory.park);
        return [
          ListingsLoaded(
            allListings: [hospital, park],
            listings: [hospital, park],
            filteredListings: [hospital, park],
            selectedCategory: null,
          ),
        ];
      },
    );
  });

  // ── search filter ─────────────────────────────────────────────────────────

  group('ListingsSearchChanged', () {
    blocTest<ListingsBloc, ListingsState>(
      'returns matching listings for query',
      build: () {
        final kigaliHosp = makeListing(id: 'h1', name: 'Kigali Hospital');
        final cityPark = makeListing(id: 'p1', name: 'City Park');
        when(mockRepo.watchListings())
            .thenAnswer((_) => Stream.value([kigaliHosp, cityPark]));
        return ListingsBloc(listingsRepository: mockRepo);
      },
      act: (bloc) async {
        bloc.add(const ListingsSubscriptionRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ListingsSearchChanged('kigali'));
      },
      skip: 2,
      expect: () {
        final kigaliHosp = makeListing(id: 'h1', name: 'Kigali Hospital');
        final cityPark = makeListing(id: 'p1', name: 'City Park');
        return [
          ListingsLoaded(
            allListings: [kigaliHosp, cityPark],
            listings: [kigaliHosp, cityPark],
            filteredListings: [kigaliHosp],
            searchQuery: 'kigali',
          ),
        ];
      },
    );

    blocTest<ListingsBloc, ListingsState>(
      'returns empty filteredListings when nothing matches',
      build: () {
        final kigaliHosp = makeListing(id: 'h1', name: 'Kigali Hospital');
        final cityPark = makeListing(id: 'p1', name: 'City Park');
        when(mockRepo.watchListings())
            .thenAnswer((_) => Stream.value([kigaliHosp, cityPark]));
        return ListingsBloc(listingsRepository: mockRepo);
      },
      act: (bloc) async {
        bloc.add(const ListingsSubscriptionRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ListingsSearchChanged('zzznomatch'));
      },
      skip: 2,
      expect: () {
        final kigaliHosp = makeListing(id: 'h1', name: 'Kigali Hospital');
        final cityPark = makeListing(id: 'p1', name: 'City Park');
        return [
          ListingsLoaded(
            allListings: [kigaliHosp, cityPark],
            listings: [kigaliHosp, cityPark],
            filteredListings: [],
            searchQuery: 'zzznomatch',
          ),
        ];
      },
    );
  });

  // ── create ────────────────────────────────────────────────────────────────

  group('ListingCreated', () {
    blocTest<ListingsBloc, ListingsState>(
      'emits ActionSuccess then ListingsLoaded with new item prepended',
      build: () {
        final existing = makeListing(id: 'existing');
        final newListing = makeListing(id: 'new', name: 'New Place');
        when(mockRepo.watchListings())
            .thenAnswer((_) => Stream.value([existing]));
        when(mockRepo.createListing(newListing))
            .thenAnswer((_) async => newListing);
        return ListingsBloc(listingsRepository: mockRepo);
      },
      act: (bloc) async {
        bloc.add(const ListingsSubscriptionRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(ListingCreated(makeListing(id: 'new', name: 'New Place')));
      },
      skip: 2,
      expect: () => [
        const ListingsActionSuccess('Listing added successfully.'),
        isA<ListingsLoaded>().having(
          (s) => s.allListings.map((l) => l.id).toList(),
          'allListings ids',
          containsAll(['new', 'existing']),
        ),
      ],
    );
  });

  // ── update ────────────────────────────────────────────────────────────────

  group('ListingUpdated', () {
    blocTest<ListingsBloc, ListingsState>(
      'emits ActionSuccess then ListingsLoaded with updated item',
      build: () {
        final original = makeListing(id: 'l1', name: 'Old Name');
        final updated = makeListing(id: 'l1', name: 'New Name');
        when(mockRepo.watchListings())
            .thenAnswer((_) => Stream.value([original]));
        when(mockRepo.updateListing(updated)).thenAnswer((_) => Future<void>.value());
        return ListingsBloc(listingsRepository: mockRepo);
      },
      act: (bloc) async {
        bloc.add(const ListingsSubscriptionRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(ListingUpdated(makeListing(id: 'l1', name: 'New Name')));
      },
      skip: 2,
      expect: () => [
        const ListingsActionSuccess('Listing updated successfully.'),
        isA<ListingsLoaded>().having(
          (s) => s.allListings.first.name,
          'updated name',
          'New Name',
        ),
      ],
    );
  });

  // ── delete ────────────────────────────────────────────────────────────────

  group('ListingDeleted', () {
    blocTest<ListingsBloc, ListingsState>(
      'emits ActionSuccess then ListingsLoaded without deleted item',
      build: () {
        final listing = makeListing(id: 'l1');
        when(mockRepo.watchListings())
            .thenAnswer((_) => Stream.value([listing]));
        when(mockRepo.deleteListing('l1')).thenAnswer((_) => Future<void>.value());
        return ListingsBloc(listingsRepository: mockRepo);
      },
      act: (bloc) async {
        bloc.add(const ListingsSubscriptionRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ListingDeleted('l1'));
      },
      skip: 2,
      expect: () => [
        const ListingsActionSuccess('Listing deleted.'),
        isA<ListingsLoaded>()
            .having((s) => s.allListings, 'allListings', isEmpty),
      ],
    );
  });

  // ── error ─────────────────────────────────────────────────────────────────

  group('ListingsError', () {
    blocTest<ListingsBloc, ListingsState>(
      'emits ListingsError when repository throws on createListing',
      build: () {
        when(mockRepo.watchListings())
            .thenAnswer((_) => Stream<List<Listing>>.value([]));
        when(mockRepo.createListing(any))
            .thenThrow(Exception('Firestore error'));
        return ListingsBloc(listingsRepository: mockRepo);
      },
      act: (bloc) async {
        bloc.add(const ListingsSubscriptionRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(ListingCreated(makeListing()));
      },
      skip: 2,
      expect: () => [isA<ListingsError>()],
    );
  });
}
