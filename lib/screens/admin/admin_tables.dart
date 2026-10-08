import 'package:flutter/material.dart';

import '../../models/doctor_model.dart';
import '../../models/exercise_model.dart';
import '../../models/food_model.dart';
import 'admin_crud_page.dart';

// ======================================================
// hena el config beta3 kol table el admin y2dar y3dlo
// 3shan tzawed field gedid: zawed AdminField hena bas
// ======================================================

const _common = [
  AdminField('name', 'Name', required: true),
  AdminField('description', 'Description', type: FieldType.multiline),
  AdminField('address', 'Address'),
  AdminField('phone', 'Phone'),
  AdminField('image_url', 'Image URL'),
  AdminField('rating', 'Rating (0 - 5)', type: FieldType.decimal),
  AdminField('latitude', 'Latitude', type: FieldType.decimal),
  AdminField('longitude', 'Longitude', type: FieldType.decimal),
];

const doctorsTable = AdminTable(
  table: 'doctors',
  title: 'Doctors',
  icon: Icons.medical_services_rounded,
  titleKey: 'full_name',
  subtitleKeys: ['specialization', 'clinic_name'],
  fields: [
    AdminField('full_name', 'Full name', required: true),
    AdminField('specialization', 'Specialization', type: FieldType.choice, options: DoctorModel.specializations, required: true),
    AdminField('bio', 'Bio', type: FieldType.multiline),
    AdminField('years_experience', 'Years of experience', type: FieldType.integer),
    AdminField('consultation_price', 'Consultation price (EGP)', type: FieldType.decimal),
    AdminField('clinic_name', 'Clinic name'),
    AdminField('clinic_address', 'Clinic address'),
    AdminField('phone', 'Phone'),
    AdminField('avatar_url', 'Photo URL'),
    AdminField('rating', 'Rating (0 - 5)', type: FieldType.decimal),
    AdminField('latitude', 'Latitude', type: FieldType.decimal),
    AdminField('longitude', 'Longitude', type: FieldType.decimal),
    AdminField('is_available', 'Available for booking', type: FieldType.boolean),
  ],
);

const availabilityTable = AdminTable(
  table: 'doctor_availability',
  title: 'Doctor Availability',
  icon: Icons.schedule_rounded,
  titleKey: 'doctor_id',
  subtitleKeys: ['day_of_week', 'start_time', 'end_time'],
  orderBy: 'day_of_week',
  fields: [
    AdminField('doctor_id', 'Doctor', type: FieldType.reference, refTable: 'doctors', refLabel: 'full_name', required: true),
    AdminField('day_of_week', 'Day', type: FieldType.weekday, required: true),
    AdminField('start_time', 'Start time', type: FieldType.time, required: true),
    AdminField('end_time', 'End time', type: FieldType.time, required: true),
    AdminField('is_available', 'Active', type: FieldType.boolean),
  ],
);

const appointmentsTable = AdminTable(
  table: 'appointments',
  title: 'Appointments',
  icon: Icons.event_note_rounded,
  titleKey: 'patient_id',
  subtitleKeys: ['doctor_id', 'appointment_date', 'appointment_time', 'status'],
  fields: [
    AdminField('patient_id', 'Patient', type: FieldType.reference, refTable: 'profiles', refLabel: 'full_name', required: true),
    AdminField('doctor_id', 'Doctor', type: FieldType.reference, refTable: 'doctors', refLabel: 'full_name', required: true),
    AdminField('appointment_date', 'Date', type: FieldType.date, required: true),
    AdminField('appointment_time', 'Time', type: FieldType.time, required: true),
    AdminField('status', 'Status', type: FieldType.choice,
        options: ['pending', 'confirmed', 'completed', 'cancelled', 'rejected'], required: true),
    AdminField('notes', 'Notes', type: FieldType.multiline),
  ],
);

const prescriptionsTable = AdminTable(
  table: 'prescriptions',
  title: 'Prescriptions',
  icon: Icons.medication_liquid_rounded,
  titleKey: 'medicine_name',
  subtitleKeys: ['patient_id', 'doctor_id', 'dosage'],
  fields: [
    AdminField('patient_id', 'Patient', type: FieldType.reference, refTable: 'profiles', refLabel: 'full_name', required: true),
    AdminField('doctor_id', 'Doctor', type: FieldType.reference, refTable: 'doctors', refLabel: 'full_name', required: true),
    AdminField('medicine_name', 'Medicine name', required: true),
    AdminField('dosage', 'Dosage', required: true),
    AdminField('instructions', 'Instructions', type: FieldType.multiline),
  ],
);

const pharmaciesTable = AdminTable(
  table: 'pharmacies',
  title: 'Pharmacies',
  icon: Icons.local_pharmacy_rounded,
  titleKey: 'name',
  subtitleKeys: ['address'],
  fields: [..._common, AdminField('is_open', 'Open now', type: FieldType.boolean)],
);

const medicinesTable = AdminTable(
  table: 'medicines',
  title: 'Medicines',
  icon: Icons.medication_rounded,
  titleKey: 'name',
  subtitleKeys: ['pharmacy_id', 'price', 'stock_quantity'],
  fields: [
    AdminField('pharmacy_id', 'Pharmacy', type: FieldType.reference, refTable: 'pharmacies', required: true),
    AdminField('name', 'Name', required: true),
    AdminField('category', 'Category'),
    AdminField('description', 'Description', type: FieldType.multiline),
    AdminField('price', 'Price (EGP)', type: FieldType.decimal, required: true),
    AdminField('stock_quantity', 'Stock quantity', type: FieldType.integer, required: true),
    AdminField('image_url', 'Image URL'),
    AdminField('prescription_required', 'Prescription required', type: FieldType.boolean),
  ],
);

const exercisesTable = AdminTable(
  table: 'exercises',
  title: 'Exercises',
  icon: Icons.fitness_center_rounded,
  titleKey: 'name',
  subtitleKeys: ['category', 'difficulty', 'duration_minutes'],
  fields: [
    AdminField('name', 'Name', required: true),
    AdminField('category', 'Category', type: FieldType.choice, options: ExerciseModel.categories, required: true),
    AdminField('difficulty', 'Difficulty', type: FieldType.choice, options: ExerciseModel.difficulties, required: true),
    AdminField('description', 'Description', type: FieldType.multiline),
    AdminField('duration_minutes', 'Duration (minutes)', type: FieldType.integer, required: true),
    AdminField('calories', 'Calories', type: FieldType.integer, required: true),
    AdminField('image_url', 'Image URL'),
    AdminField('video_url', 'Video URL'),
  ],
);

const gymsTable = AdminTable(
  table: 'gyms',
  title: 'Gyms',
  icon: Icons.sports_gymnastics_rounded,
  titleKey: 'name',
  subtitleKeys: ['address'],
  fields: _common,
);

// el rabt ben el gym w el tamareen elly feh
const gymExercisesTable = AdminTable(
  table: 'gym_exercises',
  title: 'Gym Exercises',
  icon: Icons.link_rounded,
  titleKey: 'gym_id',
  subtitleKeys: ['exercise_id'],
  orderBy: 'gym_id',
  fields: [
    AdminField('gym_id', 'Gym', type: FieldType.reference, refTable: 'gyms', required: true),
    AdminField('exercise_id', 'Exercise', type: FieldType.reference, refTable: 'exercises', required: true),
  ],
);

const restaurantsTable = AdminTable(
  table: 'restaurants',
  title: 'Restaurants',
  icon: Icons.restaurant_rounded,
  titleKey: 'name',
  subtitleKeys: ['address'],
  fields: [..._common, AdminField('is_open', 'Open now', type: FieldType.boolean)],
);

const foodTable = AdminTable(
  table: 'food_items',
  title: 'Food',
  icon: Icons.ramen_dining_rounded,
  titleKey: 'name',
  subtitleKeys: ['restaurant_id', 'category', 'price'],
  fields: [
    AdminField('restaurant_id', 'Restaurant', type: FieldType.reference, refTable: 'restaurants', required: true),
    AdminField('name', 'Name', required: true),
    AdminField('category', 'Category', type: FieldType.choice, options: FoodModel.categories, required: true),
    AdminField('description', 'Description', type: FieldType.multiline),
    AdminField('price', 'Price (EGP)', type: FieldType.decimal, required: true),
    AdminField('calories', 'Calories', type: FieldType.integer),
    AdminField('protein', 'Protein (g)', type: FieldType.integer),
    AdminField('carbs', 'Carbs (g)', type: FieldType.integer),
    AdminField('fats', 'Fats (g)', type: FieldType.integer),
    AdminField('image_url', 'Image URL'),
    AdminField('is_healthy', 'Healthy', type: FieldType.boolean),
  ],
);

// el users: el admin y3dl el esm / phone / role bas
// (mynf3sh y-add aw y-delete account men hena, da byt3ml men Supabase Auth)
const usersTable = AdminTable(
  table: 'profiles',
  title: 'Users',
  icon: Icons.people_alt_rounded,
  titleKey: 'full_name',
  subtitleKeys: ['email', 'role'],
  canAdd: false,
  canDelete: false,
  fields: [
    AdminField('full_name', 'Full name', required: true),
    AdminField('phone', 'Phone'),
    AdminField('role', 'Role', type: FieldType.choice, options: ['patient', 'admin'], required: true),
  ],
);

// el list elly btzhar f el admin dashboard
const allAdminTables = [
  doctorsTable,
  availabilityTable,
  appointmentsTable,
  prescriptionsTable,
  pharmaciesTable,
  medicinesTable,
  exercisesTable,
  gymsTable,
  gymExercisesTable,
  restaurantsTable,
  foodTable,
  usersTable,
];

