WORKING_DIR=$PWD
MIGRATIONS_DIR=$WORKING_DIR/priv/repo/migrations
cd $MIGRATIONS_DIR
echo $MIGRATIONS_DIR
find . -iname "*.exs" -exec rm {} \;

RESOURCE_SNAPSHOTS_DIR=$WORKING_DIR/priv/resource_snapshots/repo
echo $RESOURCE_SNAPSHOTS_DIR
cd $RESOURCE_SNAPSHOTS_DIR
find . -iname "*.json" -exec rm {} \;  