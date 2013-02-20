angular.module('SidebarController', ['ngHttp', 'ngFilter']);
angular.module('ProgressController', ['ngHttp']);
angular.module('VoteController', ['ngFilter']);

function SidebarController ($scope, $http, $filter) {
  var issueCache, spinner;

  issueCache = {};
  spinner    = document.getElementById('spinner');

  $scope.votes = [];
  $scope.dates = [];

  $scope.$watch('selectedDate', function() {
    $scope.votes = [];

    if ($scope.selectedDate) {
      var dateString = $filter('date')($scope.parseDate($scope.selectedDate), 'yyMMdd');
      $scope.links = [
        {href: 'http://stortinget.no/no/Saker-og-publikasjoner/Publikasjoner/Referater/Stortinget/2009-2010/' + dateString, title: 'Referat'}
      ]
      $scope.fetchVoteList(true);
    }
  });

  $scope.fetchDates = function() {
    $http({method: 'GET', url: '/dates'}).
      success(function(data, status, headers, config) {
        $scope.dates = data;
      }).
      error(function(data, status, headers, config) {
        alert('' + status + data);
      });
  };

  $scope.fetchVoteList = function(clear) {
    var date = $scope.parseDate($scope.selectedDate)
    var str = $filter('date')(date, 'yyyy-MM-dd H:mm:ss');

    if(clear) {
      $scope.voteList = [];
    }

    $http({method: 'GET', url: '/votelist/' + str}).
      success(function(data, status, headers, config) {
        $scope.voteList = data;
      }).
      error(function(data, status, headers, config) {
        alert('' + status + data);
      });
  };

  $scope.fetchVotes = function(timestamp) {
    var str = $filter('date')($scope.parseDate(timestamp), 'yyyy-MM-dd H:mm:ss');

    spinner.style.display = 'block';

    $http({method: 'GET', url: '/votes/' + str}).
      success(function(votes, status, headers, config) {
        $scope.votes = votes;
        spinner.style.display = 'none';
        _.each(votes, function(vote) {
          $scope.fetchIssuesFor(vote);
        });
      }).
      error(function(data, status, headers, config) {
        alert('' + status + data);
      });
  };

  $scope.fetchIssuesFor = function(vote) {
    function addIssue(issue) {
      vote.issues = vote.issues || [];
      vote.issues.push(issue);
      vote.issues = _.sortBy(vote.issues, 'description');
    }

    _.each(vote.externalIssueId.split(','), function(id) {
     if (issueCache[id]) {
         addIssue(issueCache[id])
         return;
     }

     $http({method: 'GET', url: 'http://next.holderdeord.no/parliament-issues/' + id + '.json'}).
       success(function(data, status, headers, config) {
         issueCache[id] = data;
         addIssue(data)
       }).
       error(function(data, status, headers, config) {
         console && console.log(status + ': ' + data);
       });
    });
  };

  $scope.saveVotes = function() {
    $http({method: 'POST', url: '/votes/?username=' + window.cleanerUsername, data: $scope.votes}).
      success(function(data, status, headers, config) {
        $scope.votes = data;
        $scope.fetchVoteList();
      }).
      error(function(data, status, headers, config) {
        alert('' + status + data);
      });
  };

  $scope.deleteProposition = function(prop) {
    if (!window.confirm("Er du sikker på at du vil slette forslaget?")) {
      return;
    }

    _.each($scope.votes, function(v) {
      v.propositions = _.reject(v.propositions, function(p) { return _.isEqual(p, prop); });
    });

    $scope.saveVotes();
  };

  $scope.textFor = function(bool) {
    return {true: 'Ja', false: 'Nei'}[bool];
  };

  $scope.parseDate = function(str) {
    return new Date(str);
  };

  $scope.activeVote = null;

  $scope.openVote = function(vote) {
    $scope.activeVote = vote;
    $scope.votes = [];
    $scope.fetchVotes(vote.time);
  }

  $scope.fetchDates();
};

function PropositionController ($scope) {
  $scope.approve = function() {
    $scope.prop.editing = false;

    $scope.prop.metadata          = $scope.prop.metadata || {};
    $scope.prop.metadata.status   = 'approved';
    $scope.prop.metadata.username = window.cleanerUsername;

    $scope.saveVotes();
  };

  $scope.reject = function() {
    $scope.prop.editing = false;

    $scope.prop.metadata          = $scope.prop.metadata || {};
    $scope.prop.metadata.reason   = window.prompt('Hva er galt?')
    $scope.prop.metadata.status   = 'rejected';
    $scope.prop.metadata.username = window.cleanerUsername;

    $scope.saveVotes();
  };

  $scope.cancel = function() {
    $scope.prop.editing = false;
    _.extend($scope.prop, $scope.propBeforeToggle);
    $scope.saveVotes();
  };

  $scope.toggleEdit = function() {
    $scope.propBeforeToggle = angular.copy($scope.prop);
    $scope.prop.editing = !$scope.prop.editing;
  };

  $scope.statusText = function(status) {
    return {
      'approved': 'Godkjent',
      'rejected': 'Avvist'
    }[status]
  };
}

function ProgressController ($scope, $http) {
  this.scope = $scope;
  this.http  = $http;

  $scope.percentage = function(a, b) {
    return a * 100 / b;
  };

  this.update();

  var controller = this;
  setInterval(function() {
    $scope.$apply(controller.update.bind(controller));
  }, 5000)
}

ProgressController.prototype.update = function() {
  var scope = this.scope;

  this.http({method: 'GET', url: '/stats'}).
    success(function(data, status, headers, config) {
      scope.stats = data;
    }).
    error(function(data, status, headers, config) {
      console && console.log("could not update stats");
  });
};


function VoteController ($scope, $filter) {
  $scope.timeString = $filter('date')($scope.parseDate($scope.vote.time), 'HH:mm:ss');

  $scope.addProposition = function() {
    $scope.addingProposition = true;
    $scope.newProposition = {
      kind: "hdo#propositions",
      body: "",
      description: "",
      externalId: "",
      onBehalfOf: "",
      metadata: {
        status: 'approved',
        username: window.cleanerUsername
      }
    };
  };

  $scope.saveNewProposition = function() {
    $scope.newProposition.externalId = md5($scope.vote.time + $scope.newProposition.body);
    $scope.vote.propositions.push($scope.newProposition);

    $scope.addingProposition = false;
    $scope.newProposition = null;

    $scope.saveVotes();
  };

  $scope.editVote = function() {
    $scope.vote.editing = true;
  };

  $scope.saveVote = function() {
    $scope.vote.editing = false;

    var str = $filter('date')($scope.parseDate($scope.vote.time), 'yyyy/MM/dd');
    $scope.vote.time = str + ' ' + $scope.timeString;

    $scope.saveVotes();
  };

}

