import { Calendar, Clock, FileText, TrendingDown, TrendingUp, User } from 'lucide-react';
import React, { useEffect, useState } from 'react';
import { useToast } from '../../contexts/ToastContext';
import api from '../../services/api';

interface AttendanceSummary {
  totalDays: number;
  presentDays: number;
  absentDays: number;
  lateDays: number;
  excusedDays: number;
  attendancePercentage: number;
  attendanceDetails: AttendanceDetail[];
}

interface AttendanceDetail {
  date: string;
  period: string;
  status: 'PRESENT' | 'ABSENT' | 'LATE' | 'EXCUSED';
  professorName: string;
  notes?: string;
  remarks?: string;
}

interface StudentAttendanceDetailsProps {
  studentId: string;
}

const StudentAttendanceDetails: React.FC<StudentAttendanceDetailsProps> = ({ studentId }) => {
  const { showToast } = useToast();
  const [attendanceSummary, setAttendanceSummary] = useState<AttendanceSummary | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (studentId) {
      loadAttendanceSummary();
    }
  }, [studentId]);

  const loadAttendanceSummary = async () => {
    try {
      setLoading(true);
      console.log('Loading attendance summary for student:', studentId);
      const response = await api.get(`/attendance/student/${studentId}/summary`);
      setAttendanceSummary(response.data);
      console.log('Student attendance summary loaded:', response.data);
    } catch (error: any) {
      console.error('Error loading student attendance:', error);
      // Don't show error toast if it's just no attendance data
      if (error.response?.status !== 404) {
        showToast('Failed to load attendance data', 'error');
      }
      setAttendanceSummary({
        totalDays: 0,
        presentDays: 0,
        absentDays: 0,
        lateDays: 0,
        excusedDays: 0,
        attendancePercentage: 0,
        attendanceDetails: []
      });
    } finally {
      setLoading(false);
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'PRESENT': return 'bg-green-100 text-green-800';
      case 'ABSENT': return 'bg-red-100 text-red-800';
      case 'LATE': return 'bg-yellow-100 text-yellow-800';
      case 'EXCUSED': return 'bg-blue-100 text-blue-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'PRESENT': return '✓';
      case 'ABSENT': return '✗';
      case 'LATE': return '⏰';
      case 'EXCUSED': return '📝';
      default: return '?';
    }
  };

  const getAttendanceGrade = (percentage: number) => {
    if (percentage >= 95) return { grade: 'Excellent', color: 'text-green-600' };
    if (percentage >= 85) return { grade: 'Very Good', color: 'text-blue-600' };
    if (percentage >= 75) return { grade: 'Good', color: 'text-yellow-600' };
    if (percentage >= 65) return { grade: 'Average', color: 'text-orange-600' };
    return { grade: 'Poor', color: 'text-red-600' };
  };

  if (loading) {
    return (
      <div className="bg-white rounded-xl shadow-sm border p-6">
        <div className="flex items-center justify-center h-32">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-purple-600"></div>
        </div>
      </div>
    );
  }

  if (!attendanceSummary) {
    return (
      <div className="bg-white rounded-xl shadow-sm border p-8 text-center">
        <FileText className="h-16 w-16 text-gray-300 mx-auto mb-4" />
        <h3 className="text-lg font-medium text-gray-900 mb-2">No Attendance Data</h3>
        <p className="text-gray-600">No attendance records found for this student.</p>
      </div>
    );
  }

  const attendanceGrade = getAttendanceGrade(attendanceSummary.attendancePercentage);

  return (
    <div className="bg-white rounded-xl shadow-sm border p-6">
      <h3 className="text-lg font-semibold mb-6">Attendance Summary</h3>

      {/* Attendance Overview Cards */}
      <div className="grid grid-cols-2 md:grid-cols-5 gap-4 mb-6">
        <div className="text-center p-4 bg-gray-50 rounded-lg">
          <div className="text-2xl font-bold text-gray-900">{attendanceSummary.totalDays}</div>
          <div className="text-sm text-gray-600">Total Days</div>
        </div>
        
        <div className="text-center p-4 bg-green-50 rounded-lg">
          <div className="text-2xl font-bold text-green-600">{attendanceSummary.presentDays}</div>
          <div className="text-sm text-gray-600">Present</div>
        </div>
        
        <div className="text-center p-4 bg-red-50 rounded-lg">
          <div className="text-2xl font-bold text-red-600">{attendanceSummary.absentDays}</div>
          <div className="text-sm text-gray-600">Absent</div>
        </div>
        
        <div className="text-center p-4 bg-yellow-50 rounded-lg">
          <div className="text-2xl font-bold text-yellow-600">{attendanceSummary.lateDays}</div>
          <div className="text-sm text-gray-600">Late</div>
        </div>
        
        <div className="text-center p-4 bg-purple-50 rounded-lg">
          <div className={`text-2xl font-bold ${attendanceGrade.color}`}>
            {attendanceSummary.attendancePercentage.toFixed(1)}%
          </div>
          <div className="text-sm text-gray-600">Attendance</div>
          <div className={`text-xs font-medium ${attendanceGrade.color}`}>
            {attendanceGrade.grade}
          </div>
        </div>
      </div>

      {/* Attendance Progress Bar */}
      <div className="mb-6">
        <div className="flex justify-between items-center mb-2">
          <span className="text-sm font-medium text-gray-700">Attendance Progress</span>
          <span className={`text-sm font-medium ${attendanceGrade.color}`}>
            {attendanceSummary.attendancePercentage.toFixed(1)}% ({attendanceGrade.grade})
          </span>
        </div>
        <div className="w-full bg-gray-200 rounded-full h-3">
          <div
            className={`h-3 rounded-full transition-all ${
              attendanceSummary.attendancePercentage >= 85 ? 'bg-green-500' :
              attendanceSummary.attendancePercentage >= 75 ? 'bg-yellow-500' : 'bg-red-500'
            }`}
            style={{ width: `${Math.min(attendanceSummary.attendancePercentage, 100)}%` }}
          />
        </div>
        <div className="flex justify-between text-xs text-gray-500 mt-1">
          <span>0%</span>
          <span>Required: 75%</span>
          <span>Excellent: 85%</span>
          <span>100%</span>
        </div>
      </div>

      {/* Recent Attendance Records */}
      {attendanceSummary.attendanceDetails.length > 0 && (
        <div>
          <h4 className="font-medium text-gray-900 mb-4">Recent Attendance Records</h4>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-gray-200 bg-gray-50">
                  <th className="text-left py-3 px-4 font-medium">Date</th>
                  <th className="text-left py-3 px-4 font-medium">Period</th>
                  <th className="text-center py-3 px-4 font-medium">Status</th>
                  <th className="text-left py-3 px-4 font-medium">Professor</th>
                  <th className="text-left py-3 px-4 font-medium">Remarks</th>
                </tr>
              </thead>
              <tbody>
                {attendanceSummary.attendanceDetails
                  .sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime())
                  .slice(0, 10) // Show last 10 records
                  .map((detail, index) => (
                    <tr key={index} className="border-b border-gray-100 hover:bg-gray-50">
                      <td className="py-3 px-4">
                        <div className="flex items-center space-x-2">
                          <Calendar className="h-4 w-4 text-gray-400" />
                          <span>{new Date(detail.date).toLocaleDateString()}</span>
                        </div>
                      </td>
                      <td className="py-3 px-4">
                        <div className="flex items-center space-x-2">
                          <Clock className="h-4 w-4 text-gray-400" />
                          <span className="font-medium">{detail.period}</span>
                        </div>
                      </td>
                      <td className="text-center py-3 px-4">
                        <span className={`px-3 py-1 rounded-full text-xs font-medium ${getStatusColor(detail.status)}`}>
                          {getStatusIcon(detail.status)} {detail.status}
                        </span>
                      </td>
                      <td className="py-3 px-4">
                        <div className="flex items-center space-x-2">
                          <User className="h-4 w-4 text-gray-400" />
                          <span>{detail.professorName}</span>
                        </div>
                      </td>
                      <td className="py-3 px-4 text-gray-600">
                        <div>
                          {detail.remarks && (
                            <div className="text-sm">{detail.remarks}</div>
                          )}
                          {detail.notes && (
                            <div className="text-xs text-gray-500 mt-1">Class: {detail.notes}</div>
                          )}
                        </div>
                      </td>
                    </tr>
                  ))}
              </tbody>
            </table>
          </div>
          
          {attendanceSummary.attendanceDetails.length > 10 && (
            <div className="text-center mt-4">
              <p className="text-sm text-gray-500">
                Showing 10 most recent records out of {attendanceSummary.attendanceDetails.length} total
              </p>
            </div>
          )}
        </div>
      )}

      {/* Attendance Insights */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div className="bg-gray-50 p-4 rounded-lg">
          <h4 className="font-medium text-gray-900 mb-3">Performance Analysis</h4>
          <div className="space-y-2 text-sm">
            <div className="flex justify-between">
              <span className="text-gray-600">Attendance Rate:</span>
              <span className={`font-medium ${attendanceGrade.color}`}>
                {attendanceSummary.attendancePercentage.toFixed(1)}%
              </span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-600">Performance Grade:</span>
              <span className={`font-medium ${attendanceGrade.color}`}>
                {attendanceGrade.grade}
              </span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-600">Days Present:</span>
              <span className="font-medium text-green-600">
                {attendanceSummary.presentDays}/{attendanceSummary.totalDays}
              </span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-600">Days Absent:</span>
              <span className="font-medium text-red-600">{attendanceSummary.absentDays}</span>
            </div>
          </div>
        </div>

        <div className="bg-gray-50 p-4 rounded-lg">
          <h4 className="font-medium text-gray-900 mb-3">Attendance Status</h4>
          <div className="space-y-2 text-sm">
            {attendanceSummary.attendancePercentage >= 75 ? (
              <div className="flex items-center space-x-2 text-green-700">
                <TrendingUp className="h-4 w-4" />
                <span>Meeting attendance requirements</span>
              </div>
            ) : (
              <div className="flex items-center space-x-2 text-red-700">
                <TrendingDown className="h-4 w-4" />
                <span>Below minimum attendance requirement</span>
              </div>
            )}
            
            <div className="text-gray-600">
              {attendanceSummary.attendancePercentage >= 85 && (
                <p>Excellent attendance! Keep up the good work.</p>
              )}
              {attendanceSummary.attendancePercentage >= 75 && attendanceSummary.attendancePercentage < 85 && (
                <p>Good attendance. Try to maintain consistency.</p>
              )}
              {attendanceSummary.attendancePercentage < 75 && (
                <p>Attendance below requirement. Please improve to avoid academic issues.</p>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default StudentAttendanceDetails;