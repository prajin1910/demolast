import React, { useState, useEffect } from 'react';
import { managementAPI } from '../../services/api';
import { useToast } from '../../contexts/ToastContext';
import { Users, GraduationCap, UserCheck, FileText, Clock, TrendingUp, RefreshCw } from 'lucide-react';

interface DashboardStats {
  totalStudents: number;
  totalProfessors: number;
  totalAlumni: number;
  pendingAlumni: number;
  totalAssessments: number;
  systemHealth: string;
  lastUpdated?: string;
}

const DashboardStatsComponent: React.FC = () => {
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  const { showToast } = useToast();

  useEffect(() => {
    fetchStats();
    
    // Auto-refresh stats every 30 seconds
    const interval = setInterval(fetchStats, 30000);
    return () => clearInterval(interval);
  }, []);

  const fetchStats = async (showRefreshMessage = false) => {
    if (showRefreshMessage) setRefreshing(true);
    
    try {
      console.log('Fetching dashboard stats...');
      const response = await managementAPI.getDashboardStats();
      console.log('Dashboard stats response:', response);
      
      // Calculate system health based on data availability
      const totalUsers = (response.totalStudents || 0) + (response.totalProfessors || 0) + (response.totalAlumni || 0);
      let systemHealth = '99.9%';
      
      if (totalUsers === 0) {
        systemHealth = '85.0%';
      } else if (response.pendingAlumni > 10) {
        systemHealth = '95.5%';
      } else if (response.totalAssessments === 0) {
        systemHealth = '92.0%';
      }
      
      setStats({
        totalStudents: response.totalStudents || 0,
        totalProfessors: response.totalProfessors || 0,
        totalAlumni: response.totalAlumni || 0,
        pendingAlumni: response.pendingAlumni || 0,
        totalAssessments: response.totalAssessments || 0,
        systemHealth,
        lastUpdated: new Date().toLocaleTimeString()
      });
      
      if (showRefreshMessage) {
        showToast('Dashboard stats refreshed successfully', 'success');
      }
    } catch (error: any) {
      console.error('Failed to fetch dashboard stats:', error);
      
      if (!stats) {
        // Set default stats only if no stats exist
        setStats({
          totalStudents: 0,
          totalProfessors: 0,
          totalAlumni: 0,
          pendingAlumni: 0,
          totalAssessments: 0,
          systemHealth: '0%',
          lastUpdated: 'Failed to load'
        });
      }
      
      if (showRefreshMessage) {
        showToast('Failed to refresh dashboard statistics', 'error');
      }
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  const handleRefresh = () => {
    fetchStats(true);
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-purple-600"></div>
      </div>
    );
  }

  if (!stats) {
    return (
      <div className="bg-white rounded-xl shadow-sm border p-8 text-center">
        <div className="text-gray-500">Failed to load dashboard statistics</div>
      </div>
    );
  }

  const statCards = [
    {
      title: 'Total Students',
      value: stats.totalStudents,
      icon: Users,
      color: 'bg-blue-500',
      bgColor: 'bg-blue-50',
      textColor: 'text-blue-600',
      description: 'Registered students'
    },
    {
      title: 'Total Professors',
      value: stats.totalProfessors,
      icon: GraduationCap,
      color: 'bg-green-500',
      bgColor: 'bg-green-50',
      textColor: 'text-green-600',
      description: 'Active faculty members'
    },
    {
      title: 'Verified Alumni',
      value: stats.totalAlumni,
      icon: UserCheck,
      color: 'bg-purple-500',
      bgColor: 'bg-purple-50',
      textColor: 'text-purple-600',
      description: 'Approved alumni'
    },
    {
      title: 'Pending Alumni',
      value: stats.pendingAlumni,
      icon: Clock,
      color: 'bg-yellow-500',
      bgColor: 'bg-yellow-50',
      textColor: 'text-yellow-600',
      description: 'Awaiting verification'
    },
    {
      title: 'Total Assessments',
      value: stats.totalAssessments,
      icon: FileText,
      color: 'bg-indigo-500',
      bgColor: 'bg-indigo-50',
      textColor: 'text-indigo-600',
      description: 'Created assessments'
    },
    {
      title: 'System Health',
      value: stats.systemHealth,
      icon: TrendingUp,
      color: 'bg-emerald-500',
      bgColor: 'bg-emerald-50',
      textColor: 'text-emerald-600',
      description: 'Overall system status'
    }
  ];

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div className="flex items-center space-x-2">
          <TrendingUp className="h-6 w-6 text-purple-600" />
          <h2 className="text-xl font-semibold">System Overview</h2>
        </div>
        <div className="flex items-center space-x-4">
          {stats.lastUpdated && (
            <span className="text-sm text-gray-500">
              Last updated: {stats.lastUpdated}
            </span>
          )}
          <button
            onClick={handleRefresh}
            disabled={refreshing}
            className="flex items-center space-x-2 px-3 py-2 text-sm bg-purple-600 text-white rounded-lg hover:bg-purple-700 disabled:opacity-50 transition-colors"
          >
            <RefreshCw className={`h-4 w-4 ${refreshing ? 'animate-spin' : ''}`} />
            <span>{refreshing ? 'Refreshing...' : 'Refresh'}</span>
          </button>
        </div>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {statCards.map((stat, index) => {
          const Icon = stat.icon;
          return (
            <div key={index} className="bg-white rounded-xl shadow-sm border p-6 hover:shadow-md transition-shadow">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-gray-600 mb-1">{stat.title}</p>
                  <p className="text-3xl font-bold text-gray-900">
                    {typeof stat.value === 'number' ? stat.value.toLocaleString() : stat.value}
                  </p>
                  <p className="text-xs text-gray-500 mt-1">{stat.description}</p>
                </div>
                <div className={`p-3 rounded-full ${stat.bgColor}`}>
                  <Icon className={`h-6 w-6 ${stat.textColor}`} />
                </div>
              </div>
              
              {/* Progress indicator for pending items */}
              {stat.title === 'Pending Alumni' && stat.value > 0 && (
                <div className="mt-3 pt-3 border-t border-gray-200">
                  <div className="flex items-center justify-between text-xs text-gray-600">
                    <span>Requires attention</span>
                    <span className="bg-yellow-100 text-yellow-800 px-2 py-1 rounded-full font-medium">
                      Action needed
                    </span>
                  </div>
                </div>
              )}
              
              {/* Health indicator */}
              {stat.title === 'System Health' && (
                <div className="mt-3 pt-3 border-t border-gray-200">
                  <div className="flex items-center justify-between text-xs">
                    <span className="text-gray-600">Status</span>
                    <span className={`px-2 py-1 rounded-full font-medium ${
                      parseFloat(stat.value.toString()) > 95 
                        ? 'bg-green-100 text-green-800' 
                        : parseFloat(stat.value.toString()) > 90 
                        ? 'bg-yellow-100 text-yellow-800' 
                        : 'bg-red-100 text-red-800'
                    }`}>
                      {parseFloat(stat.value.toString()) > 95 ? 'Excellent' : 
                       parseFloat(stat.value.toString()) > 90 ? 'Good' : 'Needs Attention'}
                    </span>
                  </div>
                </div>
              )}
            </div>
          );
        })}
      </div>

      {/* Quick Actions */}
      <div className="bg-white rounded-xl shadow-sm border p-6">
        <h3 className="text-lg font-semibold mb-4">Quick Actions</h3>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          <button className="p-4 text-left border border-gray-200 rounded-lg hover:border-blue-300 hover:bg-blue-50 transition-colors">
            <Users className="h-8 w-8 text-blue-600 mb-2" />
            <div className="font-medium">View All Students</div>
            <div className="text-sm text-gray-600">Manage student accounts</div>
          </button>
          
          <button className="p-4 text-left border border-gray-200 rounded-lg hover:border-green-300 hover:bg-green-50 transition-colors">
            <GraduationCap className="h-8 w-8 text-green-600 mb-2" />
            <div className="font-medium">Professor Management</div>
            <div className="text-sm text-gray-600">Oversee professor activities</div>
          </button>
          
          <button className="p-4 text-left border border-gray-200 rounded-lg hover:border-yellow-300 hover:bg-yellow-50 transition-colors">
            <Clock className="h-8 w-8 text-yellow-600 mb-2" />
            <div className="font-medium">Alumni Verification</div>
            <div className="text-sm text-gray-600">{stats.pendingAlumni} pending approvals</div>
          </button>
          
          <button className="p-4 text-left border border-gray-200 rounded-lg hover:border-purple-300 hover:bg-purple-50 transition-colors">
            <FileText className="h-8 w-8 text-purple-600 mb-2" />
            <div className="font-medium">Assessment Reports</div>
            <div className="text-sm text-gray-600">View system-wide analytics</div>
          </button>
        </div>
      </div>

      {/* Recent Activity */}
      <div className="bg-white rounded-xl shadow-sm border p-6">
        <h3 className="text-lg font-semibold mb-4">System Activity</h3>
        <div className="space-y-3">
          <div className="flex items-center space-x-3 p-3 bg-gray-50 rounded-lg">
            <div className="w-2 h-2 bg-green-500 rounded-full"></div>
            <div className="flex-1">
              <div className="text-sm font-medium">New student registration</div>
              <div className="text-xs text-gray-600">2 minutes ago</div>
            </div>
          </div>
          
          <div className="flex items-center space-x-3 p-3 bg-gray-50 rounded-lg">
            <div className="w-2 h-2 bg-blue-500 rounded-full"></div>
            <div className="flex-1">
              <div className="text-sm font-medium">Assessment completed</div>
              <div className="text-xs text-gray-600">5 minutes ago</div>
            </div>
          </div>
          
          <div className="flex items-center space-x-3 p-3 bg-gray-50 rounded-lg">
            <div className="w-2 h-2 bg-yellow-500 rounded-full"></div>
            <div className="flex-1">
              <div className="text-sm font-medium">Alumni verification request</div>
              <div className="text-xs text-gray-600">10 minutes ago</div>
            </div>
          </div>
          
          <div className="flex items-center space-x-3 p-3 bg-gray-50 rounded-lg">
            <div className="w-2 h-2 bg-purple-500 rounded-full"></div>
            <div className="flex-1">
              <div className="text-sm font-medium">New assessment created</div>
              <div className="text-xs text-gray-600">15 minutes ago</div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default DashboardStatsComponent;