import React, { useState } from 'react';
import { assessmentAPI, activityAPI } from '../../services/api';
import { useToast } from '../../contexts/ToastContext';
import { Brain, Play, Clock, CheckCircle, XCircle } from 'lucide-react';

interface Assessment {
  id: string;
  title: string;
  questions: Question[];
  domain: string;
  difficulty: string;
  duration: number;
}

interface Question {
  question: string;
  options: string[];
  correctAnswer: number;
  explanation: string;
}

const AIAssessment: React.FC = () => {
  const [assessment, setAssessment] = useState<Assessment | null>(null);
  const [loading, setLoading] = useState(false);
  const [currentQuestion, setCurrentQuestion] = useState(0);
  const [answers, setAnswers] = useState<number[]>([]);
  const [isActive, setIsActive] = useState(false);
  const [timeLeft, setTimeLeft] = useState(0);
  const [showResults, setShowResults] = useState(false);
  const [results, setResults] = useState<any>(null);

  const { showToast } = useToast();

  const domains = [
    'Computer Science', 'Mathematics', 'Physics', 'Chemistry',
    'Biology', 'English', 'History', 'Geography'
  ];

  const difficulties = ['Easy', 'Medium', 'Hard'];

  const [assessmentConfig, setAssessmentConfig] = useState({
    domain: '',
    difficulty: '',
    numberOfQuestions: 5
  });

  const generateAssessment = async () => {
    if (!assessmentConfig.domain || !assessmentConfig.difficulty) {
      showToast('Please select domain and difficulty', 'error');
      return;
    }

    setLoading(true);
    try {
      console.log('AIAssessment: Generating assessment with config:', assessmentConfig);
      const response = await assessmentAPI.generateAIAssessment(assessmentConfig);
      console.log('AIAssessment: Assessment generated successfully');
      setAssessment(response);
      setAnswers(new Array(response.questions.length).fill(-1));
      setCurrentQuestion(0);
      setShowResults(false);
      setResults(null);
      
      // Log activity
      try {
        await activityAPI.logActivity('AI_ASSESSMENT', 'Generated AI assessment');
      } catch (activityError) {
        console.warn('Failed to log activity:', activityError);
      }
      showToast('Assessment generated successfully!', 'success');
    } catch (error: any) {
      console.error('AIAssessment: Error generating assessment:', error);
      showToast(error.message || 'Failed to generate assessment', 'error');
    } finally {
      setLoading(false);
    }
  };

  const startAssessment = () => {
    if (!assessment) return;
    
    setIsActive(true);
    setTimeLeft(assessment.duration * 60); // Convert minutes to seconds
    
    const timer = setInterval(() => {
      setTimeLeft(prev => {
        if (prev <= 1) {
          clearInterval(timer);
          submitAssessment();
          return 0;
        }
        return prev - 1;
      });
    }, 1000);
  };

  const submitAssessment = async () => {
    if (!assessment) return;

    setIsActive(false);
    
    // Calculate results
    let score = 0;
    const feedback: any[] = [];

    answers.forEach((answer, index) => {
      const question = assessment.questions[index];
      const isCorrect = answer === question.correctAnswer;
      if (isCorrect) score++;

      feedback.push({
        questionIndex: index,
        question: question.question,
        selectedOption: answer >= 0 ? question.options[answer] : 'Not answered',
        correctOption: question.options[question.correctAnswer],
        explanation: question.explanation,
        isCorrect
      });
    });

    const percentage = (score / assessment.questions.length) * 100;

    setResults({
      score,
      totalMarks: assessment.questions.length,
      percentage,
      feedback
    });
    setShowResults(true);

    // Log activity
    await activityAPI.logActivity('AI_ASSESSMENT', `Completed AI assessment - Score: ${score}/${assessment.questions.length}`);
    showToast(`Assessment completed! Score: ${score}/${assessment.questions.length}`, 'success');
  };

  const formatTime = (seconds: number) => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  if (showResults && results) {
    return (
      <div className="space-y-6">
        <div className="bg-white rounded-xl shadow-sm border p-6">
          <h2 className="text-2xl font-bold mb-4">Assessment Results</h2>
          
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
            <div className="bg-blue-50 p-4 rounded-lg text-center">
              <div className="text-2xl font-bold text-blue-600">{results.score}</div>
              <div className="text-sm text-gray-600">Correct Answers</div>
            </div>
            <div className="bg-gray-50 p-4 rounded-lg text-center">
              <div className="text-2xl font-bold text-gray-600">{results.totalMarks}</div>
              <div className="text-sm text-gray-600">Total Questions</div>
            </div>
            <div className="bg-green-50 p-4 rounded-lg text-center">
              <div className="text-2xl font-bold text-green-600">{results.percentage.toFixed(1)}%</div>
              <div className="text-sm text-gray-600">Percentage</div>
            </div>
          </div>

          <div className="space-y-4">
            <h3 className="text-lg font-semibold">Detailed Feedback</h3>
            {results.feedback.map((item: any, index: number) => (
              <div key={index} className="border rounded-lg p-4 space-y-3">
                <div className="flex items-center space-x-2">
                  {item.isCorrect ? (
                    <CheckCircle className="h-5 w-5 text-green-500" />
                  ) : (
                    <XCircle className="h-5 w-5 text-red-500" />
                  )}
                  <span className="font-medium">Question {index + 1}</span>
                </div>
                
                <p className="text-gray-700">{item.question}</p>
                
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
                  <div>
                    <span className="font-medium text-red-600">Your Answer: </span>
                    {item.selectedOption}
                  </div>
                  <div>
                    <span className="font-medium text-green-600">Correct Answer: </span>
                    {item.correctOption}
                  </div>
                </div>
                
                <div className="bg-gray-50 p-3 rounded-lg">
                  <span className="font-medium">Explanation: </span>
                  {item.explanation}
                </div>
              </div>
            ))}
          </div>

          <button
            onClick={() => {
              setAssessment(null);
              setShowResults(false);
              setResults(null);
            }}
            className="mt-6 w-full bg-blue-600 text-white py-3 px-4 rounded-lg hover:bg-blue-700 transition-colors"
          >
            Take Another Assessment
          </button>
        </div>
      </div>
    );
  }

  if (assessment && isActive) {
    const currentQ = assessment.questions[currentQuestion];
    
    return (
      <div className="space-y-6">
        {/* Timer and Progress */}
        <div className="bg-white rounded-xl shadow-sm border p-4">
          <div className="flex justify-between items-center">
            <div className="flex items-center space-x-2">
              <Clock className="h-5 w-5 text-blue-600" />
              <span className="font-medium">Time Left: {formatTime(timeLeft)}</span>
            </div>
            <div className="text-sm text-gray-600">
              Question {currentQuestion + 1} of {assessment.questions.length}
            </div>
          </div>
          <div className="w-full bg-gray-200 rounded-full h-2 mt-2">
            <div
              className="bg-blue-600 h-2 rounded-full transition-all"
              style={{ width: `${((currentQuestion + 1) / assessment.questions.length) * 100}%` }}
            />
          </div>
        </div>

        {/* Question */}
        <div className="bg-white rounded-xl shadow-sm border p-6">
          <h3 className="text-lg font-semibold mb-4">{currentQ.question}</h3>
          
          <div className="space-y-3">
            {currentQ.options.map((option, index) => (
              <button
                key={index}
                onClick={() => {
                  const newAnswers = [...answers];
                  newAnswers[currentQuestion] = index;
                  setAnswers(newAnswers);
                }}
                className={`w-full text-left p-4 rounded-lg border-2 transition-colors ${
                  answers[currentQuestion] === index
                    ? 'border-blue-500 bg-blue-50'
                    : 'border-gray-200 hover:border-gray-300'
                }`}
              >
                <span className="font-medium mr-3">{String.fromCharCode(65 + index)}.</span>
                {option}
              </button>
            ))}
          </div>

          <div className="flex justify-between mt-6">
            <button
              onClick={() => setCurrentQuestion(Math.max(0, currentQuestion - 1))}
              disabled={currentQuestion === 0}
              className="px-6 py-2 border border-gray-300 rounded-lg disabled:opacity-50 disabled:cursor-not-allowed hover:bg-gray-50 transition-colors"
            >
              Previous
            </button>
            
            {currentQuestion === assessment.questions.length - 1 ? (
              <button
                onClick={submitAssessment}
                className="px-6 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors"
              >
                Submit Assessment
              </button>
            ) : (
              <button
                onClick={() => setCurrentQuestion(currentQuestion + 1)}
                className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
              >
                Next
              </button>
            )}
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Configuration */}
      <div className="bg-white rounded-xl shadow-sm border p-6">
        <div className="flex items-center space-x-2 mb-4">
          <Brain className="h-6 w-6 text-blue-600" />
          <h2 className="text-xl font-semibold">AI Assessment Generator</h2>
        </div>
        
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Domain
            </label>
            <select
              value={assessmentConfig.domain}
              onChange={(e) => setAssessmentConfig(prev => ({ ...prev, domain: e.target.value }))}
              className="w-full p-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            >
              <option value="">Select Domain</option>
              {domains.map(domain => (
                <option key={domain} value={domain}>{domain}</option>
              ))}
            </select>
          </div>
          
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Difficulty
            </label>
            <select
              value={assessmentConfig.difficulty}
              onChange={(e) => setAssessmentConfig(prev => ({ ...prev, difficulty: e.target.value }))}
              className="w-full p-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            >
              <option value="">Select Difficulty</option>
              {difficulties.map(difficulty => (
                <option key={difficulty} value={difficulty}>{difficulty}</option>
              ))}
            </select>
          </div>
          
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Number of Questions
            </label>
            <select
              value={assessmentConfig.numberOfQuestions}
              onChange={(e) => setAssessmentConfig(prev => ({ ...prev, numberOfQuestions: parseInt(e.target.value) }))}
              className="w-full p-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            >
              <option value={5}>5 Questions</option>
              <option value={10}>10 Questions</option>
              <option value={15}>15 Questions</option>
              <option value={20}>20 Questions</option>
            </select>
          </div>
        </div>
        
        <button
          onClick={generateAssessment}
          disabled={loading}
          className="w-full bg-blue-600 text-white py-3 px-4 rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors flex items-center justify-center space-x-2"
        >
          <Brain className="h-5 w-5" />
          <span>{loading ? 'Generating...' : 'Generate Assessment'}</span>
        </button>
      </div>

      {/* Generated Assessment Preview */}
      {assessment && !isActive && (
        <div className="bg-white rounded-xl shadow-sm border p-6">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-lg font-semibold">{assessment.title}</h3>
            <span className="bg-blue-100 text-blue-800 px-3 py-1 rounded-full text-sm">
              {assessment.difficulty}
            </span>
          </div>
          
          <p className="text-gray-600 mb-4">{assessment.description}</p>
          
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
            <div className="text-center p-3 bg-gray-50 rounded-lg">
              <div className="font-semibold text-gray-900">{assessment.questions.length}</div>
              <div className="text-sm text-gray-600">Questions</div>
            </div>
            <div className="text-center p-3 bg-gray-50 rounded-lg">
              <div className="font-semibold text-gray-900">{assessment.duration} min</div>
              <div className="text-sm text-gray-600">Duration</div>
            </div>
            <div className="text-center p-3 bg-gray-50 rounded-lg">
              <div className="font-semibold text-gray-900">{assessment.totalMarks}</div>
              <div className="text-sm text-gray-600">Total Marks</div>
            </div>
          </div>
          
          <button
            onClick={startAssessment}
            className="w-full bg-green-600 text-white py-3 px-4 rounded-lg hover:bg-green-700 transition-colors flex items-center justify-center space-x-2"
          >
            <Play className="h-5 w-5" />
            <span>Start Assessment</span>
          </button>
        </div>
      )}
    </div>
  );
};

export default AIAssessment;