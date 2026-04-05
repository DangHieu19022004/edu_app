import 'package:edu_app_flutter/constants/app_colors.dart';
import 'package:edu_app_flutter/constants/app_texts.dart';
import 'package:edu_app_flutter/constants/app_ui.dart';
import 'package:edu_app_flutter/models/ocr_models.dart';
import 'package:edu_app_flutter/services/api_exception.dart';
import 'package:edu_app_flutter/services/ocr_service.dart';
import 'package:edu_app_flutter/views/screens/manage_academic_transcript_screen.dart';
import 'package:edu_app_flutter/views/widgets/common_bottom_nav.dart';
import 'package:edu_app_flutter/views/widgets/grade_tabs.dart';
import 'package:edu_app_flutter/views/widgets/ocr/editable_score_table.dart';
import 'package:edu_app_flutter/views/widgets/ocr/ocr_flow_header.dart';
import 'package:flutter/material.dart';

class DetailHbaScreen extends StatefulWidget {
	const DetailHbaScreen({
		super.key,
		required this.studentId,
	});

	final String studentId;

	@override
	State<DetailHbaScreen> createState() => _DetailHbaScreenState();
}

class _DetailHbaScreenState extends State<DetailHbaScreen> {
	final OcrService _ocrService = OcrService();

	int _selectedGrade = 12;
	bool _isLoading = true;
	String? _errorMessage;
	OcrFullReportCardResponse? _data;

	@override
	void initState() {
		super.initState();
		_loadFullReportCard();
	}

	Future<void> _loadFullReportCard() async {
		setState(() {
			_isLoading = true;
			_errorMessage = null;
		});

		try {
			final response = await _ocrService.getFullReportCard(
				studentId: widget.studentId,
			);
			if (!mounted) {
				return;
			}

			setState(() {
				_data = response;
				_isLoading = false;
			});
		} on ApiException catch (e) {
			if (!mounted) {
				return;
			}
			setState(() {
				_errorMessage = e.message;
				_isLoading = false;
			});
		} catch (_) {
			if (!mounted) {
				return;
			}
			setState(() {
				_errorMessage = 'Khong tai duoc chi tiet hoc ba. Vui long thu lai.';
				_isLoading = false;
			});
		}
	}

	List<OcrScoreRow> _selectedGradeRows() {
		final classList = _data?.classList ?? const <OcrReportCardClassGroup>[];
		final gradeKey = _selectedGrade.toString();

		for (final group in classList) {
			if (group.className == gradeKey) {
				return group.subjects
						.map(
							(subject) => OcrScoreRow(
								subject: subject.name,
								hk1: subject.hk1,
								hk2: subject.hk2,
								caNam: subject.cn,
							),
						)
						.toList();
			}
		}

		return const <OcrScoreRow>[];
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			backgroundColor: AppColors.background,
			body: SafeArea(
				child: Stack(
					children: [
						Column(
							children: [
								OcrFlowHeader(
									title: AppTexts.detailHbaTitle,
									subtitle: AppTexts.detailHbaSubtitle,
									onBack: () {
										Navigator.of(context).pushReplacement(
											MaterialPageRoute(builder: (_) => const ListHbaScreen()),
										);
									},
								),
								Expanded(
									child: SingleChildScrollView(
										padding: const EdgeInsets.fromLTRB(18, 14, 18, 150),
										child: _buildBody(),
									),
								),
							],
						),
						Positioned(
							right: 0,
							left: 0,
							bottom: 0,
							child: CommonBottomNav(currentTab: BottomNavTab.classes),
						),
					],
				),
			),
		);
	}

	Widget _buildBody() {
		if (_isLoading) {
			return const Padding(
				padding: EdgeInsets.only(top: 40),
				child: Center(child: CircularProgressIndicator()),
			);
		}

		if (_errorMessage != null) {
			return Container(
				width: double.infinity,
				padding: const EdgeInsets.all(14),
				decoration: BoxDecoration(
					color: AppColors.white,
					borderRadius: BorderRadius.circular(16),
					border: Border.all(color: const Color(0xFFFFD4D4)),
				),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
						const Text(
							'Khong the tai hoc ba',
							style: TextStyle(
								fontSize: AppFontSizes.dashboardBody,
								fontWeight: FontWeight.w800,
								color: Color(0xFFB42318),
							),
						),
						const SizedBox(height: 8),
						Text(
							_errorMessage!,
							style: const TextStyle(
								fontSize: AppFontSizes.dashboardCaption,
								color: AppColors.label,
							),
						),
						const SizedBox(height: 12),
						SizedBox(
							height: 42,
							child: OutlinedButton.icon(
								onPressed: _loadFullReportCard,
								icon: const Icon(Icons.refresh_rounded),
								label: const Text('Thu lai'),
							),
						),
					],
				),
			);
		}

		return Column(
			children: [
				_buildProfileCard(),
				const SizedBox(height: 12),
				_buildResultTableCard(),
				const SizedBox(height: 12),
				_buildTeacherCommentCard(),
				const SizedBox(height: 14),
			],
		);
	}

	Widget _buildProfileCard() {
		final student = _data?.student;
		final className = _data?.className.isNotEmpty == true ? _data!.className : '';
		final schoolName = _data?.schoolName.isNotEmpty == true ? _data!.schoolName : '';
		final studentName = student?.name.isNotEmpty == true ? student!.name : '';
		final gender = student?.gender.isNotEmpty == true ? student!.gender : '';
		final dob = student?.dob.isNotEmpty == true ? student!.dob : '';
		final phone = student?.phone.isNotEmpty == true ? student!.phone : '';

		return Container(
			width: double.infinity,
			padding: const EdgeInsets.all(14),
			decoration: BoxDecoration(
				color: AppColors.white,
				borderRadius: BorderRadius.circular(16),
				border: Border.all(color: AppColors.cardBorder),
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					const Text(
						'Thong tin chung sinh vien',
						style: TextStyle(
							fontSize: AppFontSizes.dashboardBody,
							fontWeight: FontWeight.w800,
							color: AppColors.title,
						),
					),
					const SizedBox(height: 10),
					_buildInfoRow('Ho ten', studentName),
					_buildInfoRow('Lop', className),
					_buildInfoRow('Gioi tinh', gender),
					_buildInfoRow('Ngay thang nam sinh', dob),
					_buildInfoRow('Truong', schoolName),
					_buildInfoRow('So dien thoai', phone),
				],
			),
		);
	}

	Widget _buildResultTableCard() {
		final rows = _selectedGradeRows();

		return Container(
			width: double.infinity,
			decoration: BoxDecoration(
				color: AppColors.white,
				borderRadius: BorderRadius.circular(16),
				border: Border.all(color: AppColors.cardBorder),
			),
			child: Column(
				children: [
					Padding(
						padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
						child: GradeTabs(
							selectedGrade: _selectedGrade,
							onChanged: (grade) {
								if (_selectedGrade == grade) {
									return;
								}
								setState(() => _selectedGrade = grade);
							},
						),
					),
					Padding(
						padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
						child: rows.isEmpty
								? const Align(
										alignment: Alignment.centerLeft,
										child: Text(
											'Khong co du lieu diem cho lop nay.',
											style: TextStyle(
												fontSize: AppFontSizes.dashboardCaption,
												color: AppColors.subtitle,
												fontWeight: FontWeight.w600,
											),
										),
									)
								: EditableScoreTable(
										rows: rows,
										readOnly: true,
									),
					),
				],
			),
		);
	}

	Widget _buildTeacherCommentCard() {
		final comment = _data?.reportCard?.teacherComment ?? '';

		return Container(
			width: double.infinity,
			padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
			decoration: BoxDecoration(
				color: AppColors.white,
				borderRadius: BorderRadius.circular(16),
				border: Border.all(color: AppColors.cardBorder),
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					const Row(
						children: [
							Icon(Icons.comment_rounded, color: AppColors.primary, size: 20),
							SizedBox(width: 6),
							Text(
								AppTexts.detailTeacherComment,
								style: TextStyle(
									fontSize: AppFontSizes.dashboardBody,
									fontWeight: FontWeight.w800,
									color: AppColors.title,
								),
							),
						],
					),
					const SizedBox(height: 10),
					Container(
						width: double.infinity,
						padding: const EdgeInsets.all(12),
						decoration: BoxDecoration(
							color: const Color(0xFFF2F7FF),
							borderRadius: BorderRadius.circular(10),
							border: const Border(
								left: BorderSide(color: AppColors.primary, width: 4),
							),
						),
						child: Text(
							comment.isNotEmpty ? comment : 'Chua co nhan xet tu giao vien.',
							style: const TextStyle(
								fontSize: AppFontSizes.dashboardBody,
								height: 1.45,
								color: AppColors.label,
								fontStyle: FontStyle.italic,
								fontWeight: FontWeight.w500,
							),
						),
					),
				],
			),
		);
	}

	Widget _buildInfoRow(String label, String value) {
		return Padding(
			padding: const EdgeInsets.only(bottom: 8),
			child: Row(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					SizedBox(
						width: 140,
						child: Text(
							label,
							style: const TextStyle(
								fontSize: AppFontSizes.dashboardCaption,
								fontWeight: FontWeight.w700,
								color: AppColors.subtitle,
							),
						),
					),
					Expanded(
						child: Text(
							value,
							style: const TextStyle(
								fontSize: AppFontSizes.dashboardBody,
								fontWeight: FontWeight.w600,
								color: AppColors.title,
							),
						),
					),
				],
			),
		);
	}
}
